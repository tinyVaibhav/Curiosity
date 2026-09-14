import logging
from typing import Any, AsyncGenerator
from urllib.parse import parse_qs, urlencode, urlparse, urlunparse
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker, create_async_engine
from app.core.config import settings
from app.models.base import Base

logger = logging.getLogger("curiosity.database")


def normalize_database_url(raw_url: str) -> tuple[str, dict[str, Any]]:
    """
    Normalizes a PostgreSQL URL (especially from serverless cloud providers like Neon, Supabase, Render)
    for async SQLAlchemy + asyncpg:
    1. Ensures the scheme is postgresql+asyncpg:// (converts postgres:// or postgresql://).
    2. Strips sslmode query parameter and configures connect_args['ssl']=True to satisfy asyncpg.
    3. Detects PgBouncer pooler endpoints (e.g. Neon hostnames containing '-pooler') and
       sets statement_cache_size=0 to prevent transaction pooling prepared statement collisions.
    """
    url = raw_url.strip()

    # 1. Scheme normalization for asyncpg
    if url.startswith("postgres://"):
        url = "postgresql+asyncpg://" + url[len("postgres://"):]
    elif url.startswith("postgresql://") and not url.startswith("postgresql+asyncpg://"):
        url = "postgresql+asyncpg://" + url[len("postgresql://"):]

    # For SQLite URLs, return directly without connect_args
    if url.startswith("sqlite"):
        return url, {}

    parsed = urlparse(url)
    query_params = parse_qs(parsed.query)

    connect_args: dict[str, Any] = {}

    # Handle SSL for cloud PostgreSQL (Neon, Supabase, RDS)
    if "sslmode" in query_params:
        sslmode = query_params.pop("sslmode")[0]
        if sslmode in ("require", "verify-ca", "verify-full"):
            connect_args["ssl"] = True

    # Strip libpq-specific parameters not accepted by asyncpg (e.g. Neon channel_binding=require)
    for libpq_param in ("channel_binding", "target_session_attrs", "gssencmode"):
        query_params.pop(libpq_param, None)

    # Detect Neon PgBouncer pooled connections
    if parsed.hostname and "-pooler" in parsed.hostname:
        connect_args["statement_cache_size"] = 0

    # Reconstruct clean URL without unsupported asyncpg query params
    clean_query = urlencode(query_params, doseq=True)
    clean_url = urlunparse(parsed._replace(query=clean_query))

    return clean_url, connect_args


class DatabaseManager:
    def __init__(self):
        self.engine: AsyncEngine | None = None
        self.session_maker: async_sessionmaker[AsyncSession] | None = None
        self.using_fallback: bool = False

    async def initialize(self) -> None:
        """Initializes database engine with automatic fallback if PostgreSQL is unavailable locally."""
        # Try primary database (PostgreSQL / Neon)
        try:
            normalized_url, connect_args = normalize_database_url(settings.DATABASE_URL)
            primary_engine = create_async_engine(
                normalized_url,
                echo=False,
                future=True,
                pool_pre_ping=True,
                connect_args=connect_args,
            )
            # Test connection health
            async with primary_engine.connect() as conn:
                await conn.execute(text("SELECT 1"))

            # Ensure tables exist on primary database (e.g. on a fresh Neon DB)
            async with primary_engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)

            self.engine = primary_engine
            self.session_maker = async_sessionmaker(
                bind=self.engine,
                class_=AsyncSession,
                expire_on_commit=False,
                autoflush=False,
            )
            self.using_fallback = False
            logger.info("Connected successfully to primary database (PostgreSQL / Neon).")
        except Exception as e:
            if settings.AUTO_FALLBACK_DATABASE:
                logger.warning(
                    f"Could not connect to primary PostgreSQL at {settings.DATABASE_URL} ({e}). "
                    f"Falling back to local SQLite ({settings.FALLBACK_DATABASE_URL}) for testing."
                )
                self.engine = create_async_engine(
                    settings.FALLBACK_DATABASE_URL,
                    echo=False,
                    future=True,
                )
                self.session_maker = async_sessionmaker(
                    bind=self.engine,
                    class_=AsyncSession,
                    expire_on_commit=False,
                    autoflush=False,
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
