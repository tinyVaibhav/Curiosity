import asyncio
from collections import defaultdict
from datetime import date
import logging
from typing import List, Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError

from app.core.cache import cache_manager
from app.core.database import db_manager
from app.models.domain import DailyPack
from app.schemas.domain import (
    ArticleItem,
    CosmosItem,
    DailyPackSchema,
    FactItem,
    QuizItem,
)
from app.services.aggregator import AggregatorService

logger = logging.getLogger("curiosity.feed_service")

class FeedService:
    # Per-date locks to guard against thundering herds / duplicate concurrent generation
    _date_locks: dict[str, asyncio.Lock] = defaultdict(asyncio.Lock)

    @classmethod
    def _pack_to_schema(cls, model: DailyPack) -> DailyPackSchema:
        """Converts an ORM DailyPack model into DailyPackSchema."""
        return DailyPackSchema(
            id=model.id,
            pack_date=model.pack_date,
            articles=[ArticleItem(**item) for item in model.articles_json],
            quizzes=[QuizItem(**item) for item in model.quizzes_json],
            cosmos=[CosmosItem(**item) for item in model.cosmos_json],
            facts=[FactItem(**item) for item in model.facts_json],
            created_at=model.created_at,
        )

    @classmethod
    async def get_or_create_daily_pack(
        cls, target_date: date, db: Optional[AsyncSession] = None
    ) -> DailyPackSchema:
        """
        Retrieves the 15-item payload for a given date following the cache-aside pattern:
        1. Cache hit -> Instant return.
        2. Database hit -> Populate cache, return.
        3. Cache & DB miss -> Lock date, generate via AggregatorService, save to DB & Cache, return.
        """
        date_str = target_date.isoformat()
        cache_key = f"daily_pack:{date_str}"

        # 1. Check Cache
        cached_data = await cache_manager.get_json(cache_key)
        if cached_data:
            logger.debug("Cache HIT for %s", cache_key)
            return DailyPackSchema.model_validate(cached_data)

        logger.debug("Cache MISS for %s", cache_key)

        # Helper to execute DB operations within provided or standalone session
        async def _query_db(session: AsyncSession) -> Optional[DailyPack]:
            stmt = select(DailyPack).where(DailyPack.pack_date == target_date)
            result = await session.execute(stmt)
            return result.scalar_one_or_none()

        # 2. Check Database
        if db is not None:
            db_pack = await _query_db(db)
            if db_pack:
                schema = cls._pack_to_schema(db_pack)
                await cache_manager.set_json(cache_key, schema.model_dump())
                return schema
        else:
            if db_manager.session_maker:
                async with db_manager.session_maker() as session:
                    db_pack = await _query_db(session)
                    if db_pack:
                        schema = cls._pack_to_schema(db_pack)
                        await cache_manager.set_json(cache_key, schema.model_dump())
                        return schema

        # 3. Cache & DB Miss: Acquire per-date lock to prevent parallel duplicate fetches
        async with cls._date_locks[date_str]:
            # Double-check cache in case another task finished while waiting for the lock
            cached_data = await cache_manager.get_json(cache_key)
            if cached_data:
                return DailyPackSchema.model_validate(cached_data)

            # Double-check database
            if db_manager.session_maker:
                async with db_manager.session_maker() as session:
                    db_pack = await _query_db(session)
                    if db_pack:
                        schema = cls._pack_to_schema(db_pack)
                        await cache_manager.set_json(cache_key, schema.model_dump())
                        return schema

            # Fetch fresh content across external APIs
            logger.info("Generating new DailyPack on-demand for date %s", date_str)
            fresh_pack = await AggregatorService.build_daily_pack(target_date)

            # Persist to database with conflict resilience
            persisted_pack: Optional[DailyPack] = None
            if db_manager.session_maker:
                async with db_manager.session_maker() as session:
                    new_record = DailyPack(
                        pack_date=target_date,
                        articles_json=[a.model_dump() for a in fresh_pack.articles],
                        quizzes_json=[q.model_dump() for q in fresh_pack.quizzes],
                        cosmos_json=[c.model_dump() for c in fresh_pack.cosmos],
                        facts_json=[f.model_dump() for f in fresh_pack.facts],
                    )
                    session.add(new_record)
                    try:
                        await session.commit()
                        await session.refresh(new_record)
                        persisted_pack = new_record
                    except IntegrityError:
                        # Another worker or request inserted concurrently
                        await session.rollback()
                        persisted_pack = await _query_db(session)

            if persisted_pack:
                result_schema = cls._pack_to_schema(persisted_pack)
            else:
                result_schema = fresh_pack

            # Save in cache
            await cache_manager.set_json(cache_key, result_schema.model_dump())
            return result_schema

    @classmethod
    async def get_archived_dates(cls, db: AsyncSession) -> List[date]:
        """Returns all dates currently stored in the archive."""
        stmt = select(DailyPack.pack_date).order_by(DailyPack.pack_date.desc())
        result = await db.execute(stmt)
        return list(result.scalars().all())
