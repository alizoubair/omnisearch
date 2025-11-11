"""
Authentication Service
Handles user authentication, JWT tokens, and password management
"""

from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.ext.asyncio import AsyncSession
import logging

from app.core.config import settings
from app.schemas.user import Token, TokenData
from app.models.user import User

logger = logging.getLogger(__name__)

# Password hashing context
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class AuthService:
    """Authentication service for handling user auth and JWT tokens"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        # Import here to avoid circular import
        from app.services.user_service import UserService
        self.user_service = UserService(db)
    
    @staticmethod
    def verify_password(plain_password: str, hashed_password: str) -> bool:
        """Verify a password against its hash"""
        try:
            # Try bcrypt directly first
            import bcrypt
            return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))
        except Exception:
            # Fallback to passlib
            return pwd_context.verify(plain_password, hashed_password)
    
    @staticmethod
    def get_password_hash(password: str) -> str:
        """Hash a password"""
        try:
            # Ensure password is within bcrypt limits
            if len(password) > 72:
                password = password[:72]
            
            logger.info(f"Hashing password of length: {len(password)} characters")
            
            # Use bcrypt directly to avoid passlib version issues
            import bcrypt
            salt = bcrypt.gensalt()
            hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
            return hashed.decode('utf-8')
            
        except Exception as e:
            logger.error(f"Password hashing error: {e}")
            # Fallback to passlib if bcrypt direct fails
            try:
                return pwd_context.hash(password)
            except Exception as e2:
                logger.error(f"Fallback password hashing also failed: {e2}")
                raise
    
    @staticmethod
    def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
        """Create JWT access token"""
        to_encode = data.copy()
        
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(hours=settings.JWT_EXPIRATION_HOURS)
        
        to_encode.update({"exp": expire})
        encoded_jwt = jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
        return encoded_jwt
    
    @staticmethod
    def verify_token(token: str) -> Optional[TokenData]:
        """Verify and decode JWT token"""
        try:
            payload = jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
            user_id: str = payload.get("sub")
            email: str = payload.get("email")
            
            if user_id is None:
                return None
            
            token_data = TokenData(user_id=user_id, email=email)
            return token_data
        except JWTError as e:
            logger.warning(f"JWT verification failed: {e}")
            return None
    
    async def authenticate_user(self, email: str, password: str) -> Optional[Token]:
        """Authenticate user with email and password"""
        try:
            # Get user by email
            user = await self.user_service.get_by_email(email)
            if not user:
                logger.warning(f"Authentication failed: User not found for email {email}")
                return None
            
            # Verify password
            if not self.verify_password(password, user.password):
                logger.warning(f"Authentication failed: Invalid password for email {email}")
                return None
            
            # Create access token
            access_token_expires = timedelta(hours=settings.JWT_EXPIRATION_HOURS)
            access_token = self.create_access_token(
                data={"sub": str(user.id), "email": user.email},
                expires_delta=access_token_expires
            )
            
            logger.info(f"User authenticated successfully: {email}")
            return Token(
                access_token=access_token,
                token_type="bearer",
                expires_in=int(access_token_expires.total_seconds())
            )
            
        except Exception as e:
            logger.error(f"Authentication error for {email}: {e}")
            return None
    
    async def get_current_user(self, token: str) -> Optional[User]:
        """Get current user from JWT token"""
        try:
            # Verify token
            token_data = self.verify_token(token)
            if not token_data or not token_data.user_id:
                return None
            
            # Get user from database
            user = await self.user_service.get_by_id(token_data.user_id)
            return user
            
        except Exception as e:
            logger.error(f"Get current user error: {e}")
            return None
    
    async def refresh_token(self, token: str) -> Optional[Token]:
        """Refresh JWT token"""
        try:
            # Get current user from token
            user = await self.get_current_user(token)
            if not user:
                return None
            
            # Create new access token
            access_token_expires = timedelta(hours=settings.JWT_EXPIRATION_HOURS)
            access_token = self.create_access_token(
                data={"sub": str(user.id), "email": user.email},
                expires_delta=access_token_expires
            )
            
            logger.info(f"Token refreshed for user: {user.email}")
            return Token(
                access_token=access_token,
                token_type="bearer",
                expires_in=int(access_token_expires.total_seconds())
            )
            
        except Exception as e:
            logger.error(f"Token refresh error: {e}")
            return None
    
    async def change_password(self, user_id: str, old_password: str, new_password: str) -> bool:
        """Change user password"""
        try:
            # Get user
            user = await self.user_service.get_by_id(user_id)
            if not user:
                return False
            
            # Verify old password
            if not self.verify_password(old_password, user.password):
                logger.warning(f"Password change failed: Invalid old password for user {user_id}")
                return False
            
            # Hash new password
            hashed_password = self.get_password_hash(new_password)
            
            # Update password
            success = await self.user_service.update_password(user_id, hashed_password)
            
            if success:
                logger.info(f"Password changed successfully for user: {user_id}")
            
            return success
            
        except Exception as e:
            logger.error(f"Change password error for user {user_id}: {e}")
            return False