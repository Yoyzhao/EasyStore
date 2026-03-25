from typing import Any, List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import or_
from app.api import deps
from app.models.item import Item
from app.models.transaction import Transaction
from app.schemas.transaction import Transaction as TransactionSchema, InboundRequest, OutboundRequest, TransactionPagination
from app.models.user import User

router = APIRouter()

@router.get("/", response_model=TransactionPagination)
def read_transactions(
    db: Session = Depends(deps.get_db),
    skip: int = 0,
    limit: int = 100,
    search: Optional[str] = None,
    type: Optional[str] = None,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    query = db.query(Transaction)
    if search:
        query = query.filter(or_(Transaction.item_name.contains(search), Transaction.remark.contains(search)))
    if type:
        query = query.filter(Transaction.type == type)
    if start_date:
        query = query.filter(Transaction.time >= start_date)
    if end_date:
        query = query.filter(Transaction.time <= end_date)
    
    query = query.order_by(Transaction.time.desc())
    total = query.count()
    transactions = query.offset(skip).limit(limit).all()
    return {"total": total, "items": transactions}

@router.post("/inbound", response_model=TransactionSchema)
def inbound_item(
    *,
    db: Session = Depends(deps.get_db),
    inbound_in: InboundRequest,
    current_user: User = Depends(deps.get_current_active_admin),
) -> Any:
    # Check if item exists (by name and category, maybe brand)
    item = db.query(Item).filter(
        Item.name == inbound_in.name,
        Item.category == inbound_in.category,
        Item.brand == inbound_in.brand
    ).first()

    if item:
        item.quantity += inbound_in.quantity
        item.price = inbound_in.price # Update to latest price
        if inbound_in.image_url:
            item.image_url = inbound_in.image_url
        if inbound_in.remark:
            item.remark = inbound_in.remark
        if inbound_in.low_stock_threshold is not None:
            item.low_stock_threshold = inbound_in.low_stock_threshold
    else:
        item = Item(
            name=inbound_in.name,
            category=inbound_in.category,
            brand=inbound_in.brand,
            quantity=inbound_in.quantity,
            price=inbound_in.price,
            unit=inbound_in.unit,
            low_stock_threshold=inbound_in.low_stock_threshold,
            image_url=inbound_in.image_url,
            item_link=inbound_in.item_link,
            remark=inbound_in.remark,
        )
        db.add(item)
    
    db.commit()
    db.refresh(item)

    transaction = Transaction(
        item_id=item.id,
        item_name=item.name,
        type="in",
        quantity=inbound_in.quantity,
        price=inbound_in.price,
        total_value=inbound_in.quantity * inbound_in.price,
        operator=inbound_in.operator or current_user.username,
        remark=inbound_in.remark
    )
    db.add(transaction)
    db.commit()
    db.refresh(transaction)
    return transaction

@router.post("/outbound", response_model=TransactionSchema)
def outbound_item(
    *,
    db: Session = Depends(deps.get_db),
    outbound_in: OutboundRequest,
    current_user: User = Depends(deps.get_current_active_admin),
) -> Any:
    item = db.query(Item).filter(Item.id == outbound_in.item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    
    if item.quantity < outbound_in.quantity:
        raise HTTPException(status_code=400, detail=f"Insufficient stock. Current stock: {item.quantity} {item.unit}")

    # Use row-level locking or simple condition to avoid race condition
    updated_rows = db.query(Item).filter(
        Item.id == outbound_in.item_id,
        Item.quantity >= outbound_in.quantity
    ).update({"quantity": Item.quantity - outbound_in.quantity})

    if updated_rows == 0:
        db.rollback()
        raise HTTPException(status_code=400, detail="Insufficient stock or concurrent update")

    db.commit()
    db.refresh(item)

    remark_str = f"用途/去向: {outbound_in.usage or '无'}"
    if outbound_in.remark:
        remark_str += f" - {outbound_in.remark}"

    transaction = Transaction(
        item_id=item.id,
        item_name=item.name,
        type="out",
        quantity=outbound_in.quantity,
        price=item.price,
        total_value=outbound_in.quantity * item.price,
        operator=outbound_in.operator or current_user.username,
        recipient=outbound_in.recipient,
        remark=remark_str
    )
    db.add(transaction)
    db.commit()
    db.refresh(transaction)
    return transaction
