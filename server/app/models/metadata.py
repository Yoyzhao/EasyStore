from sqlalchemy import Column, Integer, String
from app.db.base_class import Base

class Dictionary(Base):
    __tablename__ = "dictionaries"

    id = Column(Integer, primary_key=True, index=True)
    type = Column(String, index=True, nullable=False) # 'category', 'brand', 'unit', 'usage'
    name = Column(String, nullable=False)
    description = Column(String, nullable=True)
