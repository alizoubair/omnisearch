"""
Document Service
Handles document CRUD operations, file processing, and storage
"""

from typing import Optional, List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete
from sqlalchemy.orm import selectinload
import logging
import uuid
import os
import aiofiles
from pathlib import Path

from app.models.document import Document
from app.models.user import User
from app.schemas.document import DocumentCreate, DocumentUpdate
from app.core.config import settings

logger = logging.getLogger(__name__)


class DocumentService:
    """Service for document management operations"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def create(self, user_id: uuid.UUID, document_data: DocumentCreate) -> Optional[Document]:
        """Create a new document"""
        try:
            # Create document instance
            document = Document(
                user_id=user_id,
                name=document_data.name,
                original_name=document_data.original_name,
                file_type=document_data.file_type,
                file_size=document_data.file_size,
                storage_path=document_data.storage_path,
                content=document_data.content,
                doc_metadata=document_data.metadata,
                status="uploading"
            )
            
            # Add to database
            self.db.add(document)
            await self.db.commit()
            await self.db.refresh(document)
            
            logger.info(f"Document created successfully: {document.id}")
            return document
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Document creation error: {e}")
            return None
    
    async def get_by_id(self, document_id: uuid.UUID, user_id: Optional[uuid.UUID] = None) -> Optional[Document]:
        """Get document by ID"""
        try:
            stmt = select(Document).where(Document.id == document_id)
            
            # Add user filter if provided
            if user_id:
                stmt = stmt.where(Document.user_id == user_id)
            
            result = await self.db.execute(stmt)
            document = result.scalar_one_or_none()
            return document
        except Exception as e:
            logger.error(f"Get document by ID error: {e}")
            return None
    
    async def get_by_user(
        self, 
        user_id: uuid.UUID, 
        limit: int = 50, 
        offset: int = 0,
        status: Optional[str] = None
    ) -> List[Document]:
        """Get documents by user ID"""
        try:
            stmt = select(Document).where(Document.user_id == user_id)
            
            # Add status filter if provided
            if status:
                stmt = stmt.where(Document.status == status)
            
            stmt = stmt.order_by(Document.created_at.desc()).limit(limit).offset(offset)
            
            result = await self.db.execute(stmt)
            documents = result.scalars().all()
            return list(documents)
        except Exception as e:
            logger.error(f"Get documents by user error: {e}")
            return []
    
    async def update(self, document_id: uuid.UUID, document_data: DocumentUpdate, user_id: Optional[uuid.UUID] = None) -> Optional[Document]:
        """Update document information"""
        try:
            # Build update data
            update_data = {}
            if document_data.name is not None:
                update_data["name"] = document_data.name
            if document_data.status is not None:
                update_data["status"] = document_data.status
            if document_data.content is not None:
                update_data["content"] = document_data.content
            if document_data.metadata is not None:
                update_data["doc_metadata"] = document_data.metadata
            
            if not update_data:
                # No data to update
                return await self.get_by_id(document_id, user_id)
            
            # Build query
            stmt = update(Document).where(Document.id == document_id)
            
            # Add user filter if provided
            if user_id:
                stmt = stmt.where(Document.user_id == user_id)
            
            stmt = stmt.values(**update_data).returning(Document)
            
            result = await self.db.execute(stmt)
            await self.db.commit()
            
            document = result.scalar_one_or_none()
            if document:
                logger.info(f"Document updated successfully: {document_id}")
            
            return document
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Document update error: {e}")
            return None
    
    async def delete(self, document_id: uuid.UUID, user_id: Optional[uuid.UUID] = None) -> bool:
        """Delete document"""
        try:
            # Get document first to get storage path
            document = await self.get_by_id(document_id, user_id)
            if not document:
                return False
            
            # Delete from database
            stmt = delete(Document).where(Document.id == document_id)
            if user_id:
                stmt = stmt.where(Document.user_id == user_id)
            
            result = await self.db.execute(stmt)
            await self.db.commit()
            
            success = result.rowcount > 0
            
            if success:
                # Delete physical file
                await self._delete_file(document.storage_path)
                logger.info(f"Document deleted: {document_id}")
            
            return success
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Document deletion error: {e}")
            return False
    
    async def update_status(self, document_id: uuid.UUID, status: str, user_id: Optional[uuid.UUID] = None) -> bool:
        """Update document status"""
        try:
            stmt = update(Document).where(Document.id == document_id)
            
            if user_id:
                stmt = stmt.where(Document.user_id == user_id)
            
            stmt = stmt.values(status=status)
            
            result = await self.db.execute(stmt)
            await self.db.commit()
            
            success = result.rowcount > 0
            if success:
                logger.info(f"Document status updated to {status}: {document_id}")
            
            return success
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Document status update error: {e}")
            return False
    
    async def search_documents(
        self, 
        user_id: uuid.UUID, 
        query: str, 
        limit: int = 20, 
        offset: int = 0
    ) -> List[Document]:
        """Search documents by name or content"""
        try:
            search_term = f"%{query}%"
            stmt = (
                select(Document)
                .where(Document.user_id == user_id)
                .where(
                    (Document.name.ilike(search_term)) |
                    (Document.content.ilike(search_term))
                )
                .order_by(Document.updated_at.desc())
                .limit(limit)
                .offset(offset)
            )
            
            result = await self.db.execute(stmt)
            documents = result.scalars().all()
            return list(documents)
        except Exception as e:
            logger.error(f"Document search error: {e}")
            return []
    
    async def get_document_stats(self, user_id: uuid.UUID) -> Dict[str, Any]:
        """Get document statistics for a user"""
        try:
            # Get total count
            total_stmt = select(Document).where(Document.user_id == user_id)
            total_result = await self.db.execute(total_stmt)
            total_count = len(total_result.scalars().all())
            
            # Get count by status
            status_counts = {}
            for status in ["uploading", "processing", "ready", "error"]:
                status_stmt = select(Document).where(
                    Document.user_id == user_id,
                    Document.status == status
                )
                status_result = await self.db.execute(status_stmt)
                status_counts[status] = len(status_result.scalars().all())
            
            return {
                "total_documents": total_count,
                "status_counts": status_counts
            }
        except Exception as e:
            logger.error(f"Document stats error: {e}")
            return {"total_documents": 0, "status_counts": {}}
    
    async def save_file(self, file_content: bytes, filename: str, user_id: uuid.UUID) -> Optional[str]:
        """Save uploaded file to storage"""
        try:
            # Create user directory
            user_dir = Path(f"uploads/{user_id}")
            user_dir.mkdir(parents=True, exist_ok=True)
            
            # Generate unique filename
            file_path = user_dir / f"{uuid.uuid4()}_{filename}"
            
            # Save file
            async with aiofiles.open(file_path, 'wb') as f:
                await f.write(file_content)
            
            logger.info(f"File saved: {file_path}")
            return str(file_path)
            
        except Exception as e:
            logger.error(f"File save error: {e}")
            return None
    
    async def _delete_file(self, file_path: str) -> bool:
        """Delete physical file"""
        try:
            if os.path.exists(file_path):
                os.remove(file_path)
                logger.info(f"File deleted: {file_path}")
                return True
            return False
        except Exception as e:
            logger.error(f"File deletion error: {e}")
            return False
    
    async def extract_text_content(self, file_path: str, file_type: str) -> Optional[str]:
        """Extract text content from uploaded file"""
        try:
            # This is a placeholder - implement actual text extraction
            # based on file type (PDF, DOCX, etc.)
            
            if file_type == "text/plain":
                async with aiofiles.open(file_path, 'r', encoding='utf-8') as f:
                    content = await f.read()
                return content
            
            # For other file types, you would use libraries like:
            # - PyPDF2 or pdfplumber for PDF
            # - python-docx for DOCX
            # - Azure Document Intelligence for advanced extraction
            
            logger.warning(f"Text extraction not implemented for file type: {file_type}")
            return None
            
        except Exception as e:
            logger.error(f"Text extraction error: {e}")
            return None