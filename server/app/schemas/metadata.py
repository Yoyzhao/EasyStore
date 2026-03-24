from typing import Optional
from pydantic import BaseModel

class DictionaryBase(BaseModel):
    type: str
    name: str
    description: Optional[str] = None

class DictionaryCreate(DictionaryBase):
    pass

class DictionaryUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None

class DictionaryInDBBase(DictionaryBase):
    id: int

    class Config:
        from_attributes = True

class Dictionary(DictionaryInDBBase):
    pass
