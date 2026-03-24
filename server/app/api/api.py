from fastapi import APIRouter
from app.api import auth, items, transactions, metadata, upload, dashboard, users, system

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(items.router, prefix="/items", tags=["items"])
api_router.include_router(transactions.router, prefix="/transactions", tags=["transactions"])
api_router.include_router(metadata.router, prefix="/metadata", tags=["metadata"])
api_router.include_router(upload.router, prefix="/upload", tags=["upload"])
api_router.include_router(dashboard.router, prefix="/dashboard", tags=["dashboard"])
api_router.include_router(system.router, prefix="/system", tags=["system"])
