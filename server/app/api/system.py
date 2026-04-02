import os
import shutil
import zipfile
import tempfile
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, BackgroundTasks
from fastapi.responses import FileResponse
from app.api import deps
from app.models.user import User
from app.core.config import settings
from app.schemas.system import SystemSettings
from app.core.system_settings import get_settings, update_settings
from app.core.datetime_utils import get_now, TZ_UTC_8

router = APIRouter()

@router.get("/settings", response_model=SystemSettings)
def read_system_settings(
    current_user: User = Depends(deps.get_current_active_admin),
):
    """
    Get system settings.
    """
    return get_settings()

@router.put("/settings", response_model=SystemSettings)
def write_system_settings(
    settings_in: SystemSettings,
    current_user: User = Depends(deps.get_current_active_admin),
):
    """
    Update system settings.
    """
    return update_settings(settings_in.model_dump())

def cleanup_file(file_path: str):
    if os.path.exists(file_path):
        try:
            os.remove(file_path)
        except:
            pass

@router.get("/backup")
def backup_system_data(
    background_tasks: BackgroundTasks,
    current_user: User = Depends(deps.get_current_active_admin),
):
    """
    Backup system data (database and uploads) into a zip file.
    """
    data_dir = settings.DATA_PATH
    if not os.path.exists(data_dir):
        raise HTTPException(status_code=404, detail="Data directory not found")

    timestamp = get_now().strftime("%Y%m%d_%H%M%S")
    backup_filename = f"easystore_backup_{timestamp}.zip"
    temp_dir = tempfile.gettempdir()
    backup_filepath = os.path.join(temp_dir, backup_filename)

    try:
        # Create a zip file containing the data directory
        with zipfile.ZipFile(backup_filepath, 'w', zipfile.ZIP_DEFLATED) as zipf:
            for root, dirs, files in os.walk(data_dir):
                for file in files:
                    file_path = os.path.join(root, file)
                    # The archive path should be relative to the data_dir's parent
                    # so when extracted, it creates/overwrites the data directory.
                    arcname = os.path.relpath(file_path, os.path.dirname(settings.DATA_PATH))
                    zipf.write(file_path, arcname)
    except Exception as e:
        if os.path.exists(backup_filepath):
            os.remove(backup_filepath)
        raise HTTPException(status_code=500, detail=f"Failed to create backup: {str(e)}")

    # Ensure the temporary zip file is removed after it's sent
    background_tasks.add_task(cleanup_file, backup_filepath)
    
    return FileResponse(
        path=backup_filepath,
        filename=backup_filename,
        media_type="application/zip"
    )

@router.post("/restore")
async def restore_system_data(
    file: UploadFile = File(...),
    current_user: User = Depends(deps.get_current_active_admin),
):
    """
    Restore system data from a zip file.
    Warning: This will overwrite existing data.
    """
    if not file.filename.endswith('.zip'):
        raise HTTPException(status_code=400, detail="Only zip files are allowed for restore")

    temp_dir = tempfile.gettempdir()
    upload_filepath = os.path.join(temp_dir, f"restore_{get_now().strftime('%Y%m%d_%H%M%S')}.zip")
    
    try:
        # Save uploaded file
        content = await file.read()
        with open(upload_filepath, 'wb') as f:
            f.write(content)
            
        # Verify it's a valid zip file
        if not zipfile.is_zipfile(upload_filepath):
            raise HTTPException(status_code=400, detail="Invalid zip file")

        # Extract to base dir (since we archived it with 'data/...' path)
        with zipfile.ZipFile(upload_filepath, 'r') as zipf:
            # Basic security check: ensure all files extract to data/
            data_dirname = os.path.basename(settings.DATA_PATH)
            for member in zipf.namelist():
                if not member.startswith(f'{data_dirname}/') and not member.startswith(f'{data_dirname}\\'):
                    raise HTTPException(status_code=400, detail="Invalid backup file structure")
                if '..' in member:
                    raise HTTPException(status_code=400, detail="Invalid path in backup file")
            
            # Close DB connection if needed? We use SQLite, it might be locked if a transaction is ongoing,
            # but for simple restore, we will just extract and overwrite.
            zipf.extractall(os.path.dirname(settings.DATA_PATH))
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to restore data: {str(e)}")
    finally:
        cleanup_file(upload_filepath)

    return {"message": "System data restored successfully"}
