"""
Document endpoints
"""

from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
import uuid

from app.core.database import get_db
from app.core.config import settings
from app.schemas.document import (
    DocumentResponse, 
    DocumentUpdate, 
    DocumentUpload,
    DocumentCreate
)
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


@router.post("/upload", response_model=DocumentUpload, status_code=status.HTTP_201_CREATED)
async def upload_document(
    file: UploadFile = File(...),
    name: Optional[str] = Form(None),
    user_id: uuid.UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Upload a new document"""
    try:
        # Validate file type
        if file.content_type not in settings.ALLOWED_FILE_TYPES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"File type {file.content_type} not allowed"
            )
        
        # Validate file size
        file_content = await file.read()
        if len(file_content) > settings.MAX_FILE_SIZE:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=f"File size exceeds maximum allowed size of {settings.MAX_FILE_SIZE} bytes"
            )
        
        document_service = DocumentService(db)
        ai_service = AIService()
        
        # Save file to storage
        storage_path = await document_service.save_file(
            file_content, 
            file.filename or "unknown", 
            user_id
        )
        
        if not storage_path:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to save file"
            )
        
        # Create document record
        document_data = DocumentCreate(
            name=name or file.filename or "Untitled Document",
            original_name=file.filename or "unknown",
            file_type=file.content_type or "application/octet-stream",
            file_size=len(file_content),
            storage_path=storage_path
        )
        
        document = await document_service.create(user_id, document_data)
        
        if not document:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create document record"
            )
        
        # Start background processing (extract text, create embeddings, index)
        # In a real application, this would be done asynchronously
        await _process_document_async(document.id, storage_path, file.content_type, db)
        
        return DocumentUpload(
            message="Document uploaded successfully",
            document_id=document.id,
            status="processing"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to upload document"
        )


@router.get("/", response_model=List[DocumentResponse])
async def get_documents(
    limit: int = 50,
    offset: int = 0,
    status_filter: Optional[str] = None,
    user_id: uuid.UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Get user's documents"""
    try:
        document_service = DocumentService(db)
        documents = await document_service.get_by_user(
            user_id=user_id,
            limit=limit,
            offset=offset,
            status=status_filter
        )
        return documents
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch documents"
        )


@router.get("/{document_id}", response_model=DocumentResponse)
async def get_document(
    document_id: uuid.UUID,
    user_id: uuid.UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Get specific document"""
    try:
        document_service = DocumentService(db)
        document = await document_service.get_by_id(document_id, user_id)
        
        if not document:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Document not found"
            )
        
        return document
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch document"
        )


@router.put("/{document_id}", response_model=DocumentResponse)
async def update_document(
    document_id: uuid.UUID,
    document_data: DocumentUpdate,
    user_id: uuid.UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Update document"""
    try:
        document_service = DocumentService(db)
        document = await document_service.update(document_id, document_data, user_id)
        
        if not document:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Document not found"
            )
        
        return document
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update document"
        )


@router.delete("/{document_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_document(
    document_id: uuid.UUID,
    user_id: uuid.UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Delete document"""
    try:
        document_service = DocumentService(db)
        success = await document_service.delete(document_id, user_id)
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Document not found"
            )
        
        return None
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete document"
        )

@router.get("/{document_id}/content")
async def get_document_content(
    document_id: uuid.UUID,
    user_id: uuid.UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Get document text content"""
    try:
        document_service = DocumentService(db)
        document = await document_service.get_by_id(document_id, user_id)
        
        if not document:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Document not found"
            )
        
        return {
            "document_id": document.id,
            "content": document.content,
            "status": document.status
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch document content"
        )


@router.post("/{document_id}/reprocess", response_model=DocumentResponse)
async def reprocess_document(
    document_id: uuid.UUID,
    user_id: uuid.UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Reprocess document (extract text, create embeddings, index)"""
    try:
        document_service = DocumentService(db)
        document = await document_service.get_by_id(document_id, user_id)
        
        if not document:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Document not found"
            )
        
        # Update status to processing
        await document_service.update_status(document_id, "processing", user_id)
        
        # Start reprocessing
        await _process_document_async(document_id, document.storage_path, document.file_type, db)
        
        # Get updated document
        updated_document = await document_service.get_by_id(document_id, user_id)
        return updated_document
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to reprocess document"
        )


@router.get("/stats/summary")
async def get_document_stats(
    user_id: uuid.UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Get document statistics for user"""
    try:
        document_service = DocumentService(db)
        stats = await document_service.get_document_stats(user_id)
        return stats
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch document statistics"
        )


async def _process_document_async(
    document_id: uuid.UUID, 
    storage_path: str, 
    file_type: str, 
    db: AsyncSession
):
    """Process document asynchronously (extract text, create embeddings, index)"""
    try:
        document_service = DocumentService(db)
        ai_service = AIService()
        
        # Extract text content
        text_content = await ai_service.extract_document_text(storage_path, file_type)
        
        if text_content:
            # Update document with extracted content
            update_data = DocumentUpdate(
                content=text_content,
                status="ready"
            )
            await document_service.update(document_id, update_data)
            
            # Create embeddings and index in search (in background)
            embeddings = await ai_service.create_document_embeddings(text_content)
            
            # Index in Azure AI Search
            document = await document_service.get_by_id(document_id)
            if document:
                await ai_service.index_document_in_search(
                    str(document.id),
                    document.name,
                    text_content,
                    document.doc_metadata or {},
                    str(document.user_id)
                )
        else:
            # Mark as error if text extraction failed
            await document_service.update_status(document_id, "error")
            
    except Exception as e:
        # Mark as error if processing failed
        await document_service.update_status(document_id, "error")
        raise e