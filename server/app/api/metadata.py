from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.api import deps
from app.models.metadata import Dictionary
from app.schemas.metadata import Dictionary as DictionarySchema, DictionaryCreate, DictionaryUpdate
from app.models.user import User

router = APIRouter()

@router.get("/", response_model=List[DictionarySchema])
def read_metadata(
    type: str,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    dictionaries = db.query(Dictionary).filter(Dictionary.type == type).all()
    return dictionaries

@router.post("/", response_model=DictionarySchema)
def create_metadata(
    *,
    db: Session = Depends(deps.get_db),
    dictionary_in: DictionaryCreate,
    current_user: User = Depends(deps.get_current_active_admin),
) -> Any:
    dictionary = Dictionary(
        type=dictionary_in.type,
        name=dictionary_in.name,
        description=dictionary_in.description
    )
    db.add(dictionary)
    db.commit()
    db.refresh(dictionary)
    return dictionary

@router.put("/{id}", response_model=DictionarySchema)
def update_metadata(
    *,
    db: Session = Depends(deps.get_db),
    id: int,
    dictionary_in: DictionaryUpdate,
    current_user: User = Depends(deps.get_current_active_admin),
) -> Any:
    dictionary = db.query(Dictionary).filter(Dictionary.id == id).first()
    if not dictionary:
        raise HTTPException(status_code=404, detail="Dictionary not found")
    
    if dictionary_in.name is not None:
        dictionary.name = dictionary_in.name
    if dictionary_in.description is not None:
        dictionary.description = dictionary_in.description
        
    db.add(dictionary)
    db.commit()
    db.refresh(dictionary)
    return dictionary

@router.delete("/{id}", response_model=DictionarySchema)
def delete_metadata(
    *,
    db: Session = Depends(deps.get_db),
    id: int,
    current_user: User = Depends(deps.get_current_active_admin),
) -> Any:
    dictionary = db.query(Dictionary).filter(Dictionary.id == id).first()
    if not dictionary:
        raise HTTPException(status_code=404, detail="Dictionary not found")
    db.delete(dictionary)
    db.commit()
    return dictionary
