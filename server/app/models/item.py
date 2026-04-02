from sqlalchemy import Column, Integer, String, Float, DateTime
from app.db.base_class import Base
from app.core.datetime_utils import get_now

class Item(Base):
    __tablename__ = "items"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True, nullable=False)
    category = Column(String, index=True, nullable=False)
    brand = Column(String, index=True, nullable=True)
    quantity = Column(Integer, default=0, nullable=False)
    price = Column(Float, default=0.0, nullable=False)
    unit = Column(String, nullable=False)
    low_stock_threshold = Column(Integer, default=0, nullable=False)
    image_url = Column(String, nullable=True)
    item_link = Column(String, nullable=True)
    remark = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), default=get_now)
    updated_at = Column(DateTime(timezone=True), default=get_now, onupdate=get_now)
