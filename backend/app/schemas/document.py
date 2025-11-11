"""
Document schemas
"""

from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
from datetime import datetime
import uuid


class DocumentBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    file_type: str
    file_size: int = Field(..., gt=0)


class DocumentCreate(DocumentBase):
    original_name: str
    storage_path: str
    content: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None


class DocumentUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    status: Optional[str] = None
    content: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None


class DocumentResponse(DocumentBase):
    id: uuid.UUID
    user_id: uuid.UUID
    original_name: str
    storage_path: str
    status: str
    content: Optional[str] = None
    doc_metadata: Optional[Dict[str, Any]] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class DocumentUpload(BaseModel):
    """Schema for file upload response"""
    message: str
    document_id: uuid.UUID
    status: str


class DocumentSearch(BaseModel):
    """Schema for document search"""
    query: str = Field(..., min_length=1)
    limit: int = Field(default=10, ge=1, le=100)
    offset: int = Field(default=0, ge=0)
    filters: Optional[Dict[str, Any]] = None


class SearchResult(BaseModel):
    """Schema for search results"""
    id: uuid.UUID
    title: str
    content: str
    document_id: uuid.UUID
    document_name: str
    score: float
    highlights: Optional[List[str]] = None
    metadata: Optional[Dict[str, Any]] = None