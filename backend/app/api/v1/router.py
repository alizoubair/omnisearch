"""
Main API router
"""

from fastapi import APIRouter
from app.api.v1.endpoints import auth, documents, chat, search

api_router = APIRouter()

# Basic health endpoint
@api_router.get("/health")
async def health():
    return {"status": "healthy", "service": "backend-api"}

# Include all endpoints
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(documents.router, prefix="/documents", tags=["Documents"])
api_router.include_router(chat.router, prefix="/chat", tags=["Chat"])
api_router.include_router(search.router, prefix="/search", tags=["Search"])