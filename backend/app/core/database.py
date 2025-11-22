"""
Database configuration and connection
"""

from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
import logging
import traceback

from app.core.config import settings

logger = logging.getLogger(__name__)

# Create async engine (lazy initialization)
engine = None

def get_engine():
    """Get or create the database engine"""
    global engine
    if engine is None:
        engine = create_async_engine(
            settings.DATABASE_URL,
            echo=settings.DEBUG,
            pool_pre_ping=True,
            pool_recycle=300,
        )
    return engine

# Create async session factory (lazy initialization)
AsyncSessionLocal = None

def get_session_factory():
    """Get or create the session factory"""
    global AsyncSessionLocal
    if AsyncSessionLocal is None:
        AsyncSessionLocal = async_sessionmaker(
            get_engine(),
            class_=AsyncSession,
            expire_on_commit=False
        )
    return AsyncSessionLocal


class Base(DeclarativeBase):
    """Base class for all database models"""
    pass


async def get_db() -> AsyncSession:
    """Dependency to get database session"""
    session_factory = get_session_factory()
    async with session_factory() as session:
        try:
            yield session
        except Exception as e:
            await session.rollback()
            logger.error(f"Database session error: {e}")
            raise
        finally:
            await session.close()


async def init_db():
    """Initialize database"""
    try:
        # Log DATABASE_URL
        db_url_masked = settings.DATABASE_URL
        if '@' in db_url_masked:
            # Mask password in connection string
            parts = db_url_masked.split('@')
            if ':' in parts[0]:
                user_pass = parts[0].split('://')[1] if '://' in parts[0] else parts[0]
                if ':' in user_pass:
                    user, _ = user_pass.split(':', 1)
                    db_url_masked = db_url_masked.split('://')[0] + '://' + user + ':***@' + '@'.join(parts[1:])
        logger.info(f"🔗 Attempting database connection to: {db_url_masked}")
        
        # Test connection
        engine = get_engine()
        async with engine.begin() as conn:
            # Import all models to ensure they are registered
            try:
                from app.models import user, document, chat
            except ImportError:
                logger.warning("Models not found, skipping table creation")
            
            # Create tables if they don't exist
            # Note: In production, use Alembic migrations
            await conn.run_sync(Base.metadata.create_all)
            
        logger.info("✅ Database connection established")
    except Exception as e:
        error_type = type(e).__name__
        error_msg = str(e) if str(e) else "No error message"
        logger.error(f"❌ Database initialization failed: {error_type}: {error_msg}")
        logger.error(f"📋 Full traceback:\n{traceback.format_exc()}")
        raise