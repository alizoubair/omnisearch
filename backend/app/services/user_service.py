"""
User Service
Handles user CRUD operations and user management
"""

from typing import Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete
from sqlalchemy.exc import IntegrityError
import logging
import uuid

from app.models.user import User
from app.schemas.user import UserCreate, UserUpdate
# AuthService import moved to method level to avoid circular import

logger = logging.getLogger(__name__)


class UserService:
    """Service for user management operations"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def create(self, user_data: UserCreate) -> Optional[User]:
        """Create a new user"""
        try:
            # Import here to avoid circular import
            from app.services.auth_service import AuthService
            
            # Hash password
            hashed_password = AuthService.get_password_hash(user_data.password)
            
            # Create user instance
            user = User(
                email=user_data.email,
                name=user_data.name,
                password=hashed_password,
                email_verified=False
            )
            
            # Add to database
            self.db.add(user)
            await self.db.commit()
            await self.db.refresh(user)
            
            logger.info(f"User created successfully: {user.email}")
            return user
            
        except IntegrityError as e:
            await self.db.rollback()
            logger.warning(f"User creation failed - email already exists: {user_data.email}")
            return None
        except Exception as e:
            await self.db.rollback()
            logger.error(f"User creation error: {e}")
            return None
    
    async def get_by_id(self, user_id: uuid.UUID) -> Optional[User]:
        """Get user by ID"""
        try:
            stmt = select(User).where(User.id == user_id)
            result = await self.db.execute(stmt)
            user = result.scalar_one_or_none()
            return user
        except Exception as e:
            logger.error(f"Get user by ID error: {e}")
            return None
    
    async def get_by_email(self, email: str) -> Optional[User]:
        """Get user by email"""
        try:
            stmt = select(User).where(User.email == email)
            result = await self.db.execute(stmt)
            user = result.scalar_one_or_none()
            return user
        except Exception as e:
            logger.error(f"Get user by email error: {e}")
            return None
    
    async def update(self, user_id: uuid.UUID, user_data: UserUpdate) -> Optional[User]:
        """Update user information"""
        try:
            # Build update data
            update_data = {}
            if user_data.name is not None:
                update_data["name"] = user_data.name
            if user_data.email is not None:
                update_data["email"] = user_data.email
            
            if not update_data:
                # No data to update
                return await self.get_by_id(user_id)
            
            # Update user
            stmt = (
                update(User)
                .where(User.id == user_id)
                .values(**update_data)
                .returning(User)
            )
            result = await self.db.execute(stmt)
            await self.db.commit()
            
            user = result.scalar_one_or_none()
            if user:
                logger.info(f"User updated successfully: {user_id}")
            
            return user
            
        except IntegrityError as e:
            await self.db.rollback()
            logger.warning(f"User update failed - email conflict: {user_id}")
            return None
        except Exception as e:
            await self.db.rollback()
            logger.error(f"User update error: {e}")
            return None
    
    async def update_password(self, user_id: uuid.UUID, hashed_password: str) -> bool:
        """Update user password"""
        try:
            stmt = (
                update(User)
                .where(User.id == user_id)
                .values(password=hashed_password)
            )
            result = await self.db.execute(stmt)
            await self.db.commit()
            
            success = result.rowcount > 0
            if success:
                logger.info(f"Password updated for user: {user_id}")
            
            return success
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Password update error: {e}")
            return False
    
    async def verify_email(self, user_id: uuid.UUID) -> bool:
        """Mark user email as verified"""
        try:
            stmt = (
                update(User)
                .where(User.id == user_id)
                .values(email_verified=True)
            )
            result = await self.db.execute(stmt)
            await self.db.commit()
            
            success = result.rowcount > 0
            if success:
                logger.info(f"Email verified for user: {user_id}")
            
            return success
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"Email verification error: {e}")
            return False
    
    async def delete(self, user_id: uuid.UUID) -> bool:
        """Delete user"""
        try:
            stmt = delete(User).where(User.id == user_id)
            result = await self.db.execute(stmt)
            await self.db.commit()
            
            success = result.rowcount > 0
            if success:
                logger.info(f"User deleted: {user_id}")
            
            return success
            
        except Exception as e:
            await self.db.rollback()
            logger.error(f"User deletion error: {e}")
            return False
    
    async def get_all(self, limit: int = 100, offset: int = 0) -> List[User]:
        """Get all users with pagination"""
        try:
            stmt = select(User).limit(limit).offset(offset)
            result = await self.db.execute(stmt)
            users = result.scalars().all()
            return list(users)
        except Exception as e:
            logger.error(f"Get all users error: {e}")
            return []
    
    async def search_by_name_or_email(self, query: str, limit: int = 20) -> List[User]:
        """Search users by name or email"""
        try:
            search_term = f"%{query}%"
            stmt = (
                select(User)
                .where(
                    (User.name.ilike(search_term)) |
                    (User.email.ilike(search_term))
                )
                .limit(limit)
            )
            result = await self.db.execute(stmt)
            users = result.scalars().all()
            return list(users)
        except Exception as e:
            logger.error(f"User search error: {e}")
            return []