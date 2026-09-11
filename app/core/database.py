import logging
from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker, create_async_engine
from app.core.config import settings
from app.models.base import Base

logger = logging.getLogger("curiosity.database")

class DatabaseManager:
    def __init__(self):
        self.engine: AsyncEngine | None = None
        self.session_maker: async_sessionmaker[AsyncSession] | None = None
        self.using_fallback: bool = False

    async def initialize(self) -> None:
        """Initializes database engine with automatic fallback if PostgreSQL is unavailable locally."""
        # Try primary database (PostgreSQL)
        try:
            primary_engine = create_async_engine(
                settings.DATABASE_URL,
                echo=False,
                future=True,
                pool_pre_ping=True
            )
            # Test connection
            async with primary_engine.connect() as conn:
                await conn.execute(primary_engine.sync_engine.dialect.statement_compiler(primary_engine.sync_engine.dialect, None).process(None) if False else primary_engine.sync_engine.dialect.do_ping(conn.connection) if hasattr(primary_engine.sync_engine.dialect, 'do_ping') else None)
            
            self.engine = primary_engine
            self.session_maker = async_sessionmaker(
                bind=self.engine,
                class_=AsyncSession,
                expire_on_commit=False,
                autoflush=False
            )
            self.using_fallback = False
            logger.info("Connected successfully to primary database (PostgreSQL).")
        except Exception as e:
            if settings.AUTO_FALLBACK_DATABASE:
                logger.warning(
                    f"Could not connect to primary PostgreSQL at {settings.DATABASE_URL} ({e}). "
                    f"Falling back to local SQLite ({settings.FALLBACK_DATABASE_URL}) for testing."
                )
                self.engine = create_async_engine(
                    settings.FALLBACK_DATABASE_URL,
                    echo=False,
                    future=True
                )
                self.session_maker = async_sessionmaker(
                    bind=self.engine,
                    class_=AsyncSession,
                    expire_on_commit=False,
                    autoflush=False
                )
                self.using_fallback = True
                # Automatically ensure tables exist for local testing
                async with self.engine.begin() as conn:
                    await conn.run_sync(Base.metadata.create_all)
                logger.info("Local SQLite database initialized successfully.")
            else:
                raise e

    async def close(self) -> None:
        if self.engine:
            await self.engine.dispose()
            self.engine = None
            self.session_maker = None

db_manager = DatabaseManager()

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Dependency to provide an async database session."""
    if db_manager.session_maker is None:
        await db_manager.initialize()

    assert db_manager.session_maker is not None
    async with db_manager.session_maker() as session:
        try:
            yield session
        finally:
            await session.close()
