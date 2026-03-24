from typing import Optional
from pydantic import BaseModel
from datetime import datetime

class TransactionBase(BaseModel):
    item_id: int
    item_name: str
    type: str # 'in' or 'out'
    quantity: int
    price: float
    total_value: float
    operator: str
    recipient: Optional[str] = None
    remark: Optional[str] = None

class TransactionCreate(TransactionBase):
    pass

class TransactionInDBBase(TransactionBase):
    id: int
    time: datetime

    class Config:
        from_attributes = True

class Transaction(TransactionInDBBase):
    pass

class InboundRequest(BaseModel):
    name: str
    category: str
    brand: Optional[str] = None
    quantity: int
    price: float
    unit: str
    low_stock_threshold: Optional[int] = 0
    image_url: Optional[str] = None
    item_link: Optional[str] = None
    remark: Optional[str] = None
    operator: str

class OutboundRequest(BaseModel):
    item_id: int
    quantity: int
    operator: str
    usage: Optional[str] = None
    recipient: Optional[str] = None
    remark: Optional[str] = None
