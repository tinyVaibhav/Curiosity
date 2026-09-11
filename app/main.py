from contextlib import asynccontextmanager
from datetime import date
from typing import Optional

from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware

from app.api.routers.discovery import router as discovery_router
from app.api.routers.feed import router as feed_router
from app.api.routers.vault import router as vault_router
from app.core.cache import cache_manager
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

    # 4. Start scheduler (00:00 UTC cron + startup pre-warm task)
    feed_scheduler.start()

    yield

    # Graceful shutdown in reverse order
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

# Standard CORS setup (allowing all for testing phase)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount API routers
app.include_router(feed_router)
app.include_router(discovery_router)
app.include_router(vault_router)


@app.get("/ping")
async def ping():
    """Health check endpoint."""
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
