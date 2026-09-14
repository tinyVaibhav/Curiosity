from contextlib import asynccontextmanager
from datetime import date
import logging
from typing import Optional

from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware

# Configure console logging format
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)

from app.api.routers.cron import router as cron_router
from app.api.routers.discovery import router as discovery_router
from app.api.routers.feed import router as feed_router
from app.api.routers.vault import router as vault_router
from app.core.cache import cache_manager
from app.core.config import settings
from app.core.database import db_manager
from app.core.http_client import start_client, stop_client
from app.core.scheduler import feed_scheduler
from app.schemas.domain import DailyPackSchema
from app.services.aggregator import AggregatorService


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan manager for all background resources: HTTP client, database, cache, and scheduler."""
    # 1. Start HTTP connection pool
    start_client()

    # 2. Initialize Database connection (PostgreSQL with SQLite fallback)
    await db_manager.initialize()

    # 3. Initialize Cache connection (Redis with in-memory TTL fallback)
    await cache_manager.initialize()

    # 4. Start internal scheduler if enabled (disabled in production when using external cron like Upstash QStash)
    if settings.ENABLE_INTERNAL_SCHEDULER:
        feed_scheduler.start()

    yield

    # Graceful shutdown in reverse order
    if settings.ENABLE_INTERNAL_SCHEDULER:
        await feed_scheduler.stop()
    await cache_manager.close()
    await db_manager.close()
    await stop_client()


app = FastAPI(
    title="Curiosity Backend",
    description="Stateless backend serving Daily Packs for the microlearning app.",
    version="1.0.0",
    lifespan=lifespan,
)

# Standard CORS setup (fully compliant with W3C wildcard specification)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount API routers
app.include_router(feed_router)
app.include_router(discovery_router)
app.include_router(vault_router)
app.include_router(cron_router)


@app.get("/health")
async def health():
    """Detailed health check revealing live database and cache connectivity."""
    if db_manager.session_maker is None:
        await db_manager.initialize()
    if cache_manager.redis_client is None and not cache_manager.is_using_memory:
        await cache_manager.initialize()

    return {
        "status": "healthy",
        "database": {
            "connected": db_manager.engine is not None,
            "provider": "PostgreSQL (Neon Live)" if not db_manager.using_fallback else "SQLite (Local Fallback)",
            "using_fallback": db_manager.using_fallback,
        },
        "cache": {
            "connected": cache_manager.redis_client is not None or cache_manager.memory_cache is not None,
            "provider": "Redis (Upstash Live)" if not cache_manager.is_using_memory else "In-Memory (Local Fallback)",
            "using_memory": cache_manager.is_using_memory,
        },
    }


@app.get("/ping")
async def ping():
    """Simple ping-pong health check."""
    return {"status": "ok", "message": "pong"}


@app.get("/test-aggregate", response_model=DailyPackSchema)
async def test_aggregate(
    target_date: Optional[date] = Query(
        default=None,
        description="Optional date to aggregate for (defaults to today). Format: YYYY-MM-DD",
    )
):
    """Direct test endpoint to trigger the aggregator and inspect the 15-item payload."""
    pack = await AggregatorService.build_daily_pack(target_date=target_date)
    return pack
