from sqlalchemy.orm import Session
from app.db import base  # noqa: F401
from app.models.user import User
from app.models.metadata import Dictionary
from app.core.security import get_password_hash
from app.db.base_class import Base
from app.db.session import engine

def init_db(db: Session) -> None:
    # Create tables
    Base.metadata.create_all(bind=engine)

    # Check if admin user exists
    user = db.query(User).filter(User.username == "admin").first()
    if not user:
        user = User(
            username="admin",
            hashed_password=get_password_hash("123456"),
            role="admin",
            is_active=True,
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    # Check if test user exists
    user = db.query(User).filter(User.username == "user").first()
    if not user:
        user = User(
            username="user",
            hashed_password=get_password_hash("123456"),
            role="user",
            is_active=True,
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    # Initialize Metadata
    if db.query(Dictionary).count() == 0:
        initial_metadata = [
            Dictionary(type="category", name="电子产品", description="手机、电脑等"),
            Dictionary(type="category", name="办公用品", description="纸张、笔具等"),
            Dictionary(type="category", name="食品饮料", description="零食、饮料等"),
            Dictionary(type="category", name="日用品", description="日常生活用品"),
            Dictionary(type="brand", name="Apple", description="苹果"),
            Dictionary(type="brand", name="得力", description="办公用品品牌"),
            Dictionary(type="brand", name="百事", description="饮料品牌"),
            Dictionary(type="unit", name="个", description=""),
            Dictionary(type="unit", name="包", description=""),
            Dictionary(type="unit", name="箱", description=""),
            Dictionary(type="unit", name="台", description=""),
            Dictionary(type="unit", name="支", description=""),
            Dictionary(type="unit", name="件", description=""),
            Dictionary(type="usage", name="研发测试", description="用于研发部门内部测试"),
            Dictionary(type="usage", name="日常办公", description="日常办公消耗"),
            Dictionary(type="usage", name="项目交付", description="交付给客户的项目物资")
        ]
        db.add_all(initial_metadata)
        db.commit()
