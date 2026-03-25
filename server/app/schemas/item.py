from typing import Optional, List
from pydantic import BaseModel
from datetime import datetime

class ItemBase(BaseModel):
    name: str
    category: str
    brand: Optional[str] = None
    price: float
    unit: str
    low_stock_threshold: Optional[int] = 0
    image_url: Optional[str] = None
    item_link: Optional[str] = None
    remark: Optional[str] = None

class ItemCreate(ItemBase):
    quantity: int

class ItemUpdate(BaseModel):
    name: Optional[str] = None
    category: Optional[str] = None
    brand: Optional[str] = None
    price: Optional[float] = None
    unit: Optional[str] = None
    low_stock_threshold: Optional[int] = None
    image_url: Optional[str] = None
    item_link: Optional[str] = None
    remark: Optional[str] = None

class ItemInDBBase(ItemBase):
    id: int
    quantity: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class Item(ItemInDBBase):
    pass

class ItemPagination(BaseModel):
    total: int
    items: List[Item]
