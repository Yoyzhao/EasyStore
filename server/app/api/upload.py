import os
import uuid
import aiofiles
from fastapi import APIRouter, Depends, File, UploadFile, HTTPException
from app.api import deps
from app.models.user import User
from app.core.config import settings
from app.core.system_settings import get_settings

router = APIRouter()

@router.post("/")
async def upload_file(
    file: UploadFile = File(...),
    current_user: User = Depends(deps.get_current_active_admin),
):
    system_settings = get_settings()
    upload_settings = system_settings.get("upload", {})
    
    file_extension = file.filename.split(".")[-1].lower()
    allowed_extensions = [ext.lower() for ext in upload_settings.get("allowed_extensions", ["jpg", "jpeg", "png", "gif", "webp"])]
    
    if file_extension not in allowed_extensions:
        raise HTTPException(status_code=400, detail=f"File extension not allowed. Allowed: {', '.join(allowed_extensions)}")
    
    # Read file content
    content = await file.read()
    
    # Check file size
    max_size_bytes = upload_settings.get("max_size_mb", 5) * 1024 * 1024
    if len(content) > max_size_bytes:
        raise HTTPException(status_code=400, detail=f"File too large. Maximum size is {upload_settings.get('max_size_mb')}MB")
    
    if not os.path.exists(settings.UPLOAD_DIR):
        os.makedirs(settings.UPLOAD_DIR)

    file_name = f"{uuid.uuid4().hex}.{file_extension}"
    file_path = os.path.join(settings.UPLOAD_DIR, file_name)

    async with aiofiles.open(file_path, 'wb') as out_file:
        await out_file.write(content)

    # Return the URL path
    return {"url": f"/uploads/{file_name}"}
