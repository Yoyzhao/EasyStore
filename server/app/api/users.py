import os
import uuid
import aiofiles
from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, File, UploadFile
from sqlalchemy.orm import Session
from app.api import deps
from app.models.user import User
from app.schemas.user import User as UserSchema, UserCreate, UserUpdate, UserUpdatePassword
from app.core.security import get_password_hash, verify_password
from app.core.config import settings
from app.core.system_settings import get_settings

router = APIRouter()

@router.get("/", response_model=List[UserSchema])
def read_users(
    db: Session = Depends(deps.get_db),
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Retrieve users.
    """
    users = db.query(User).offset(skip).limit(limit).all()
    return users

@router.post("/", response_model=UserSchema)
def create_user(
    *,
    db: Session = Depends(deps.get_db),
    user_in: UserCreate,
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Create new user.
    """
    user = db.query(User).filter(User.username == user_in.username).first()
    if user:
        raise HTTPException(
            status_code=400,
            detail="The user with this username already exists in the system.",
        )
    user = User(
        username=user_in.username,
        hashed_password=get_password_hash(user_in.password),
        role=user_in.role,
        is_active=user_in.is_active,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

@router.put("/me/password", response_model=UserSchema)
def update_password_me(
    *,
    db: Session = Depends(deps.get_db),
    body: UserUpdatePassword,
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Update own password.
    """
    if not verify_password(body.old_password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Incorrect password")
    
    current_user.hashed_password = get_password_hash(body.new_password)
    db.add(current_user)
    db.commit()
    db.refresh(current_user)
    return current_user

@router.put("/me/avatar", response_model=UserSchema)
async def update_avatar_me(
    *,
    db: Session = Depends(deps.get_db),
    file: UploadFile = File(...),
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Update own avatar.
    """
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

    file_name = f"avatar_{current_user.id}_{uuid.uuid4().hex[:8]}.{file_extension}"
    file_path = os.path.join(settings.UPLOAD_DIR, file_name)

    # Delete old avatar if exists
    if current_user.avatar:
        old_avatar_path = os.path.join(settings.UPLOAD_DIR, current_user.avatar.split("/")[-1])
        if os.path.exists(old_avatar_path):
            try:
                os.remove(old_avatar_path)
            except:
                pass

    async with aiofiles.open(file_path, 'wb') as out_file:
        await out_file.write(content)

    current_user.avatar = f"/uploads/{file_name}"
    db.add(current_user)
    db.commit()
    db.refresh(current_user)
    return current_user

@router.put("/{user_id}", response_model=UserSchema)
def update_user(
    *,
    db: Session = Depends(deps.get_db),
    user_id: int,
    user_in: UserUpdate,
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Update a user.
    """
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    update_data = user_in.model_dump(exclude_unset=True)
    if "password" in update_data:
        hashed_password = get_password_hash(update_data["password"])
        del update_data["password"]
        update_data["hashed_password"] = hashed_password
        
    for field, value in update_data.items():
        setattr(user, field, value)
        
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

@router.delete("/{user_id}", response_model=UserSchema)
def delete_user(
    *,
    db: Session = Depends(deps.get_db),
    user_id: int,
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Delete a user.
    """
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user.id == current_user.id:
        raise HTTPException(status_code=400, detail="Users cannot delete themselves.")
        
    db.delete(user)
    db.commit()
    return user
