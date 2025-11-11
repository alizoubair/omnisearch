"""
Chat Service
Handles chat sessions, messages, and AI integration
"""

from typing import Optional, List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete
from sqlalchemy.orm import selectinload
import logging
import uuid
import json

from app.models.chat import ChatSession, ChatMessage
from app.models.user import User
from app.schemas.chat import ChatSessionCreate, ChatSessionUpdate, ChatMessageCreate
from app.services.ai_service import AIService

logger = logging.getLogger(__name__)


class ChatService:
    """Service for chat management operations"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.ai_service = AIService()
    
    # Chat Session Methods
    async def create_session(self, user_id: uuid.UUID, session_data: ChatSessionCreate) -> Optional[ChatSession]:
        """Create a new chat session"""
        try:
            session = ChatSession(
                user_id=user_id,
                title=session_data.title
            )
            
            self.db.add(session)
            await self.db.commit()
            await self.db.refresh(session)
            
            logger.info(f"Chat session created: {session.id}")
            return session
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Chat session creation error: {e}")
            return None
    
    async def get_session_by_id(self, session_id: uuid.UUID, user_id: Optional[uuid.UUID] = None) -> Optional[ChatSession]:
        """Get chat session by ID"""
        try:
            stmt = select(ChatSession).where(ChatSession.id == session_id)
            
            if user_id:
                stmt = stmt.where(ChatSession.user_id == user_id)
            
            result = await self.db.execute(stmt)
            session = result.scalar_one_or_none()
            return session
        except Exception as e:
            logger.error(f"Get chat session error: {e}")
            return None
    
    async def get_user_sessions(
        self, 
        user_id: uuid.UUID, 
        limit: int = 50, 
        offset: int = 0
    ) -> List[ChatSession]:
        """Get chat sessions for a user"""
        try:
            stmt = (
                select(ChatSession)
                .where(ChatSession.user_id == user_id)
                .order_by(ChatSession.updated_at.desc())
                .limit(limit)
                .offset(offset)
            )
            
            result = await self.db.execute(stmt)
            sessions = result.scalars().all()
            return list(sessions)
        except Exception as e:
            logger.error(f"Get user sessions error: {e}")
            return []
    
    async def update_session(
        self, 
        session_id: uuid.UUID, 
        session_data: ChatSessionUpdate, 
        user_id: Optional[uuid.UUID] = None
    ) -> Optional[ChatSession]:
        """Update chat session"""
        try:
            update_data = {}
            if session_data.title is not None:
                update_data["title"] = session_data.title
            
            if not update_data:
                return await self.get_session_by_id(session_id, user_id)
            
            stmt = update(ChatSession).where(ChatSession.id == session_id)
            
            if user_id:
                stmt = stmt.where(ChatSession.user_id == user_id)
            
            stmt = stmt.values(**update_data).returning(ChatSession)
            
            result = await self.db.execute(stmt)
            await self.db.commit()
            
            session = result.scalar_one_or_none()
            if session:
                logger.info(f"Chat session updated: {session_id}")
            
            return session
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Chat session update error: {e}")
            return None
    
    async def delete_session(self, session_id: uuid.UUID, user_id: Optional[uuid.UUID] = None) -> bool:
        """Delete chat session and all messages"""
        try:
            # First, verify the session exists and belongs to the user
            session_query = select(ChatSession).where(ChatSession.id == session_id)
            if user_id:
                session_query = session_query.where(ChatSession.user_id == user_id)
            
            result = await self.db.execute(session_query)
            session = result.scalar_one_or_none()
            
            if not session:
                logger.warning(f"Session not found or access denied: {session_id}")
                return False
            
            # Delete all messages first (to avoid foreign key constraint)
            delete_messages_stmt = delete(ChatMessage).where(ChatMessage.session_id == session_id)
            await self.db.execute(delete_messages_stmt)
            
            # Then delete the session
            delete_session_stmt = delete(ChatSession).where(ChatSession.id == session_id)
            if user_id:
                delete_session_stmt = delete_session_stmt.where(ChatSession.user_id == user_id)
            
            await self.db.execute(delete_session_stmt)
            await self.db.commit()
            
            logger.info(f"Chat session and messages deleted: {session_id}")
            return True
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Chat session deletion error: {e}")
            return False
    
    # Chat Message Methods
    async def add_message(
        self, 
        session_id: uuid.UUID, 
        message_data: ChatMessageCreate,
        user_id: Optional[uuid.UUID] = None
    ) -> Optional[ChatMessage]:
        """Add message to chat session"""
        try:
            # Verify session exists and belongs to user
            session = await self.get_session_by_id(session_id, user_id)
            if not session:
                logger.warning(f"Session not found or access denied: {session_id}")
                return None
            
            # Create message
            message = ChatMessage(
                session_id=session_id,
                role=message_data.role,
                content=message_data.content,
                sources=message_data.sources
            )
            
            self.db.add(message)
            await self.db.commit()
            await self.db.refresh(message)
            
            # Update session timestamp
            await self._update_session_timestamp(session_id)
            
            logger.info(f"Message added to session {session_id}: {message.id}")
            return message
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Add message error: {e}")
            return None
    
    async def get_session_messages(
        self, 
        session_id: uuid.UUID, 
        limit: int = 100, 
        offset: int = 0,
        user_id: Optional[uuid.UUID] = None
    ) -> List[ChatMessage]:
        """Get messages for a chat session"""
        try:
            # Verify session access
            session = await self.get_session_by_id(session_id, user_id)
            if not session:
                return []
            
            stmt = (
                select(ChatMessage)
                .where(ChatMessage.session_id == session_id)
                .order_by(ChatMessage.created_at.asc())
                .limit(limit)
                .offset(offset)
            )
            
            result = await self.db.execute(stmt)
            messages = result.scalars().all()
            return list(messages)
        except Exception as e:
            logger.error(f"Get session messages error: {e}")
            return []
    
    async def process_chat_message(
        self, 
        user_id: uuid.UUID, 
        session_id: uuid.UUID, 
        user_message: str,
        document_ids: Optional[List[uuid.UUID]] = None
    ) -> Optional[ChatMessage]:
        """Process user message and generate AI response"""
        try:
            # Add user message
            user_msg_data = ChatMessageCreate(role="user", content=user_message)
            user_msg = await self.add_message(session_id, user_msg_data, user_id)
            
            if not user_msg:
                return None
            
            # Get chat history for context
            messages = await self.get_session_messages(session_id, limit=20, user_id=user_id)
            
            # Generate AI response
            # Convert UUIDs to strings for AI service
            document_id_strings = None
            if document_ids:
                document_id_strings = [str(doc_id) for doc_id in document_ids]
                logger.info(f"Processing chat message with {len(document_id_strings)} selected document(s): {document_id_strings}")
            else:
                logger.info("Processing chat message without document filter (searching all documents)")
            
            ai_response = await self.ai_service.generate_chat_response(
                user_message=user_message,
                chat_history=messages,
                user_id=str(user_id),
                document_ids=document_id_strings
            )
            
            if not ai_response:
                logger.error("Failed to generate AI response")
                return None
            
            # Add AI message
            ai_msg_data = ChatMessageCreate(
                role="assistant",
                content=ai_response["content"],
                sources=ai_response.get("sources", [])
            )
            ai_msg = await self.add_message(session_id, ai_msg_data, user_id)
            
            # Update session title if it's the first exchange
            if len(messages) <= 2:  # User message + AI response
                await self._update_session_title(session_id, user_message)
            
            return ai_msg
            
        except Exception as e:
            logger.error(f"Process chat message error: {e}")
            return None
    
    async def _update_session_timestamp(self, session_id: uuid.UUID) -> None:
        """Update session updated_at timestamp"""
        try:
            from sqlalchemy.sql import func
            stmt = (
                update(ChatSession)
                .where(ChatSession.id == session_id)
                .values(updated_at=func.now())
            )
            await self.db.execute(stmt)
            await self.db.commit()
        except Exception as e:
            logger.error(f"Update session timestamp error: {e}")
    
    async def _update_session_title(self, session_id: uuid.UUID, first_message: str) -> None:
        """Update session title based on first message"""
        try:
            # Generate a title from the first message (first 50 chars)
            title = first_message[:50].strip()
            if len(first_message) > 50:
                title += "..."
            
            stmt = (
                update(ChatSession)
                .where(ChatSession.id == session_id)
                .values(title=title)
            )
            await self.db.execute(stmt)
            await self.db.commit()
            
            logger.info(f"Session title updated: {session_id}")
        except Exception as e:
            logger.error(f"Update session title error: {e}")
    
    async def get_chat_stats(self, user_id: uuid.UUID) -> Dict[str, Any]:
        """Get chat statistics for a user"""
        try:
            # Get session count
            session_stmt = select(ChatSession).where(ChatSession.user_id == user_id)
            session_result = await self.db.execute(session_stmt)
            session_count = len(session_result.scalars().all())
            
            # Get message count
            message_stmt = (
                select(ChatMessage)
                .join(ChatSession)
                .where(ChatSession.user_id == user_id)
            )
            message_result = await self.db.execute(message_stmt)
            message_count = len(message_result.scalars().all())
            
            return {
                "total_sessions": session_count,
                "total_messages": message_count
            }
        except Exception as e:
            logger.error(f"Chat stats error: {e}")
            return {"total_sessions": 0, "total_messages": 0}