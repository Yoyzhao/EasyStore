from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.db.base_class import Base

class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(Integer, primary_key=True, index=True)
    item_id = Column(Integer, ForeignKey("items.id"), index=True, nullable=False)
    item_name = Column(String, nullable=False)
    type = Column(String, nullable=False) # 'in' or 'out'
    quantity = Column(Integer, nullable=False)
    price = Column(Float, nullable=False)
    total_value = Column(Float, nullable=False)
    operator = Column(String, nullable=False)
    recipient = Column(String, nullable=True)
    remark = Column(String, nullable=True)
    time = Column(DateTime(timezone=True), server_default=func.now())
