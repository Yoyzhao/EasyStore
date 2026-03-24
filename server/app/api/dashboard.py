from typing import Any, Dict
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.api import deps
from app.models.item import Item
from app.models.transaction import Transaction
from app.models.user import User
from datetime import datetime, timedelta

router = APIRouter()

@router.get("/stats", response_model=Dict[str, Any])
def get_dashboard_stats(
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    # Total Items
    total_items = db.query(func.count(Item.id)).scalar() or 0
    
    # Total Value
    total_value = db.query(func.sum(Item.quantity * Item.price)).scalar() or 0.0
    
    # Low Stock Items
    low_stock_items = db.query(func.count(Item.id)).filter(Item.quantity < Item.low_stock_threshold).scalar() or 0

    # Recent Transactions (Last 7 days)
    seven_days_ago = datetime.utcnow() - timedelta(days=7)
    recent_inbound = db.query(func.count(Transaction.id)).filter(
        Transaction.type == 'in',
        Transaction.time >= seven_days_ago
    ).scalar() or 0
    
    recent_outbound = db.query(func.count(Transaction.id)).filter(
        Transaction.type == 'out',
        Transaction.time >= seven_days_ago
    ).scalar() or 0

    return {
        "total_items": total_items,
        "total_value": total_value,
        "low_stock_items": low_stock_items,
        "recent_inbound": recent_inbound,
        "recent_outbound": recent_outbound
    }

@router.get("/trend", response_model=Dict[str, Any])
def get_dashboard_trend(
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    # Get last 7 days trend data
    today = datetime.utcnow().date()
    dates = [(today - timedelta(days=i)).strftime('%m-%d') for i in range(6, -1, -1)]
    
    inbound_data = []
    outbound_data = []
    
    for i in range(6, -1, -1):
        target_date = today - timedelta(days=i)
        start_of_day = datetime.combine(target_date, datetime.min.time())
        end_of_day = start_of_day + timedelta(days=1)
        
        daily_inbound = db.query(func.sum(Transaction.quantity)).filter(
            Transaction.type == 'in',
            Transaction.time >= start_of_day,
            Transaction.time < end_of_day
        ).scalar() or 0
        
        daily_outbound = db.query(func.sum(Transaction.quantity)).filter(
            Transaction.type == 'out',
            Transaction.time >= start_of_day,
            Transaction.time < end_of_day
        ).scalar() or 0
        
        inbound_data.append(int(daily_inbound))
        outbound_data.append(int(daily_outbound))
        
    return {
        "dates": dates,
        "inbound": inbound_data,
        "outbound": outbound_data
    }
