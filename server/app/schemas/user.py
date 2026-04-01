from typing import Optional
from pydantic import BaseModel
from datetime import datetime

class UserBase(BaseModel):
    username: str
    role: Optional[str] = "user"
    is_active: Optional[bool] = True
    avatar: Optional[str] = None

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    username: Optional[str] = None
    role: Optional[str] = None
    is_active: Optional[bool] = None
    password: Optional[str] = None

class UserUpdatePassword(BaseModel):
    old_password: str
    new_password: str

class UserInDBBase(UserBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True

class User(UserInDBBase):
    pass
