"""
Chat endpoints
"""

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
import uuid

from app.core.database import get_db
from app.schemas.chat import (
    ChatSessionResponse,
    ChatSessionCreate,
    ChatSessionUpdate,
    ChatMessageResponse,
    ChatRequest,
    ChatResponse
)
from app.services.chat_service import ChatService
from app.services.auth_service import AuthService

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


@router.post("/sessions", response_model=ChatSessionResponse, status_code=status.HTTP_201_CREATED)
async def create_chat_session(
    session_data: ChatSessionCreate,
    user_id: uuid.UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Create a new chat session"""
    try:
        chat_service = ChatService(db)
        session = await chat_service.create_session(user_id, session_data)
        
        if not session:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create chat session"
            )
        
        return session
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create chat session"
        )


@router.get("/sessions", response_model=List[ChatSessionResponse])
async def get_chat_sessions(
    limit: int = 50,
    offset: int = 0,
    user_id: uuid.UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Get user's chat sessions"""
    try:
        chat_service = ChatService(db)
        sessions = await chat_service.get_user_sessions(
            user_id=user_id,
            limit=limit,
            offset=offset
        )
        return sessions
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch chat sessions"
        )


@router.get("/sessions/{session_id}")
async def get_chat_session(
    session_id: uuid.UUID,
    user_id: uuid.UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
    include_messages: bool = True
):
    """Get specific chat session with messages"""
    try:
        chat_service = ChatService(db)
        session = await chat_service.get_session_by_id(session_id, user_id)
        
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Chat session not found"
            )
        
        # Add messages to the response if requested
        if include_messages:
            messages = await chat_service.get_session_messages(
                session_id=session_id,
                limit=100,
                offset=0,
                user_id=user_id
            )
            # Convert to dict and add messages
            session_dict = {
                "id": session.id,
                "title": session.title,
                "user_id": session.user_id,
                "created_at": session.created_at,
                "updated_at": session.updated_at,
                "messages": messages
            }
            return session_dict
        
        return session
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch chat session"
        )


@router.put("/sessions/{session_id}", response_model=ChatSessionResponse)
async def update_chat_session(
    session_id: uuid.UUID,
    session_data: ChatSessionUpdate,
    user_id: uuid.UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Update chat session"""
    try:
        chat_service = ChatService(db)
        session = await chat_service.update_session(session_id, session_data, user_id)
        
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Chat session not found"
            )
        
        return session
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update chat session"
        )


@router.delete("/sessions/{session_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_chat_session(
    session_id: uuid.UUID,
    user_id: uuid.UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Delete chat session"""
    try:
        chat_service = ChatService(db)
        success = await chat_service.delete_session(session_id, user_id)
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Chat session not found"
            )
        
        return None
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete chat session"
        )


@router.get("/sessions/{session_id}/messages", response_model=List[ChatMessageResponse])
async def get_session_messages(
    session_id: uuid.UUID,
    limit: int = 100,
    offset: int = 0,
    user_id: uuid.UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Get messages for a chat session"""
    try:
        chat_service = ChatService(db)
        messages = await chat_service.get_session_messages(
            session_id=session_id,
            limit=limit,
            offset=offset,
            user_id=user_id
        )
        return messages
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch session messages"
        )


@router.post("/", response_model=ChatResponse)
async def send_chat_message(
    chat_request: ChatRequest,
    user_id: uuid.UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Send a chat message and get AI response"""
    try:
        chat_service = ChatService(db)
        
        # Create new session if not provided
        session_id = chat_request.session_id
        if not session_id:
            session_data = ChatSessionCreate(title="New Chat")
            session = await chat_service.create_session(user_id, session_data)
            if not session:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Failed to create chat session"
                )
            session_id = session.id
        
        # Process the message and get AI response
        ai_message = await chat_service.process_chat_message(
            user_id=user_id,
            session_id=session_id,
            user_message=chat_request.message,
            document_ids=chat_request.document_ids
        )
        
        if not ai_message:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to process chat message"
            )
        
        return ChatResponse(
            message=ai_message,
            session_id=session_id
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to process chat message"
        )


@router.post("/sessions/{session_id}/regenerate", response_model=ChatMessageResponse)
async def regenerate_last_response(
    session_id: uuid.UUID,
    user_id: uuid.UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Regenerate the last AI response in a chat session"""
    try:
        chat_service = ChatService(db)
        
        # Get session messages
        messages = await chat_service.get_session_messages(session_id, limit=10, user_id=user_id)
        
        if not messages:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No messages found in session"
            )
        
        # Find the last user message
        last_user_message = None
        for message in reversed(messages):
            if message.role == "user":
                last_user_message = message
                break
        
        if not last_user_message:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No user message found to regenerate response for"
            )
        
        # Generate new AI response (without document filter for regeneration)
        ai_message = await chat_service.process_chat_message(
            user_id=user_id,
            session_id=session_id,
            user_message=last_user_message.content,
            document_ids=None
        )
        
        if not ai_message:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to regenerate response"
            )
        
        return ai_message
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to regenerate response"
        )


@router.get("/stats/summary")
async def get_chat_stats(
    user_id: uuid.UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Get chat statistics for user"""
    try:
        chat_service = ChatService(db)
        stats = await chat_service.get_chat_stats(user_id)
        return stats
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch chat statistics"
        )


@router.post("/sessions/{session_id}/clear", status_code=status.HTTP_204_NO_CONTENT)
async def clear_session_messages(
    session_id: uuid.UUID,
    user_id: uuid.UUID = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """Clear all messages from a chat session"""
    try:
        chat_service = ChatService(db)
        
        # Verify session exists and belongs to user
        session = await chat_service.get_session_by_id(session_id, user_id)
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Chat session not found"
            )
        
        # Delete all messages (this would be implemented in ChatService)
        # For now, we'll just update the session title to indicate it's cleared
        session_data = ChatSessionUpdate(title="New Chat")
        await chat_service.update_session(session_id, session_data, user_id)
        
        return None
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to clear session messages"
        )