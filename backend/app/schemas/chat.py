"""
Chat schemas
"""

from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
import uuid


class ChatMessageBase(BaseModel):
    role: str = Field(..., pattern="^(user|assistant)$")
    content: str = Field(..., min_length=1)


class ChatMessageCreate(ChatMessageBase):
    sources: Optional[List[Dict[str, Any]]] = None


class ChatMessageResponse(ChatMessageBase):
    id: uuid.UUID
    session_id: uuid.UUID
    sources: Optional[List[Dict[str, Any]]] = None
    created_at: datetime

    class Config:
        from_attributes = True


class ChatSessionBase(BaseModel):
    title: str = Field(default="New Chat", max_length=255)


class ChatSessionCreate(ChatSessionBase):
    pass


class ChatSessionUpdate(BaseModel):
    title: Optional[str] = Field(None, max_length=255)


class ChatSessionResponse(ChatSessionBase):
    id: uuid.UUID
    user_id: uuid.UUID
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ChatSessionWithMessages(ChatSessionResponse):
    messages: List[ChatMessageResponse] = []

    class Config:
        from_attributes = True


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1)
    session_id: Optional[uuid.UUID] = None
    document_ids: Optional[List[uuid.UUID]] = None


class ChatResponse(BaseModel):
    message: ChatMessageResponse
    session_id: uuid.UUID


class DocumentSource(BaseModel):
    """Schema for document sources in chat responses"""
    document_id: uuid.UUID
    document_name: str
    page_number: Optional[int] = None
    relevance_score: float = Field(..., ge=0.0, le=1.0)
    snippet: str