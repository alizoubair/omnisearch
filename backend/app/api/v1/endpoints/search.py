"""
Search endpoints
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
import uuid

from app.core.database import get_db
from app.schemas.document import DocumentSearch, SearchResult
from app.services.document_service import DocumentService
from app.services.auth_service import AuthService
from app.services.ai_service import AIService

router = APIRouter()
security = HTTPBearer()


async def get_current_user_id(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db)
) -> uuid.UUID:
    """Get current authenticated user ID"""
    auth_service = AuthService(db)
    user = await auth_service.get_current_user(credentials.credentials)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    return user.id


@router.post("/documents", response_model=List[SearchResult])
async def search_documents(
    search_request: DocumentSearch,
    user_id: uuid.UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Search documents using AI-powered semantic search"""
    try:
        ai_service = AIService()
        
        # Perform AI-powered search
        search_results = await ai_service.search_documents(
            query=search_request.query,
            user_id=str(user_id),
            limit=search_request.limit
        )
        
        # Convert to SearchResult schema
        results = []
        for result in search_results:
            search_result = SearchResult(
                id=uuid.uuid4(),  # Generate a search result ID
                title=result["title"],
                content=result["content"],
                document_id=uuid.UUID(result["document_id"]),
                document_name=result["document_name"],
                score=result["score"],
                highlights=result.get("highlights", []),
                metadata=result.get("metadata", {})
            )
            results.append(search_result)
        
        return results
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to search documents"
        )


@router.get("/documents/simple", response_model=List[SearchResult])
async def simple_document_search(
    q: str = Query(..., description="Search query"),
    limit: int = Query(default=10, ge=1, le=100, description="Number of results to return"),
    offset: int = Query(default=0, ge=0, description="Number of results to skip"),
    user_id: uuid.UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Simple document search using database text search"""
    try:
        document_service = DocumentService(db)
        
        # Search documents in database
        documents = await document_service.search_documents(
            user_id=user_id,
            query=q,
            limit=limit,
            offset=offset
        )
        
        # Convert to SearchResult schema
        results = []
        for doc in documents:
            # Create a simple search result from document
            content_preview = (doc.content or "")[:500] + "..." if doc.content and len(doc.content) > 500 else (doc.content or "")
            
            search_result = SearchResult(
                id=uuid.uuid4(),
                title=doc.name,
                content=content_preview,
                document_id=doc.id,
                document_name=doc.name,
                score=0.8,  # Default score for database search
                highlights=[q] if q.lower() in doc.name.lower() or (doc.content and q.lower() in doc.content.lower()) else [],
                metadata=doc.metadata or {}
            )
            results.append(search_result)
        
        return results
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to search documents"
        )

