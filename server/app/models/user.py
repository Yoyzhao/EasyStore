from sqlalchemy import Column, Integer, String, Boolean, DateTime
from app.db.base_class import Base
from app.core.datetime_utils import get_now

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(String, default="user") # 'admin' or 'user'
    is_active = Column(Boolean, default=True)
    avatar = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), default=get_now)
