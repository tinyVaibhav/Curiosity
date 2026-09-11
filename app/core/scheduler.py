import asyncio
from datetime import date, datetime, timezone, timedelta
import logging
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from sqlalchemy import delete
from app.core.database import db_manager
from app.models.domain import DailyPack
from app.services.feed_service import FeedService

logger = logging.getLogger("curiosity.scheduler")

class FeedScheduler:
    def __init__(self):
        self.scheduler = AsyncIOScheduler(timezone=timezone.utc)
        self._prewarm_task: asyncio.Task | None = None

    async def _daily_midnight_job(self) -> None:
        """Midnight 00:00 UTC job that pre-aggregates and caches the new day's feed, then prunes expired packs."""
        today_utc = datetime.now(timezone.utc).date()
        logger.info("Executing daily midnight UTC feed aggregation for %s", today_utc)
        try:
            await FeedService.get_or_create_daily_pack(today_utc)
            logger.info("Daily feed successfully generated and cached for %s", today_utc)
        except Exception as e:
            logger.error("Error during scheduled midnight aggregation for %s: %r", today_utc, e)

        # Enforce 30-day rolling data retention
        await self.prune_expired_packs(today_utc)

    async def prune_expired_packs(self, reference_date: date | None = None) -> int:
        """Purges any historical daily packs older than 30 days to enforce scarcity and compliance."""
        ref = reference_date or datetime.now(timezone.utc).date()
        cutoff_date = ref - timedelta(days=30)
        logger.info("Enforcing 30-day rolling retention policy: pruning packs older than %s", cutoff_date)

        try:
            if db_manager.session_maker is None:
                await db_manager.initialize()

            assert db_manager.session_maker is not None
            async with db_manager.session_maker() as session:
                async with session.begin():
                    stmt = delete(DailyPack).where(DailyPack.pack_date < cutoff_date)
                    res = await session.execute(stmt)
                    deleted_count = res.rowcount or 0
                    logger.info("Successfully purged %d expired daily pack(s) older than %s", deleted_count, cutoff_date)
                    return deleted_count
        except Exception as exc:
            logger.warning("Error pruning expired daily packs: %r", exc)
            return 0

    async def _prewarm_on_startup(self) -> None:
        """Background task to ensure today's feed is ready as soon as the server boots and retention is enforced."""
        today_utc = datetime.now(timezone.utc).date()
        logger.info("Pre-warming today's feed (%s) on application startup...", today_utc)
        try:
            await FeedService.get_or_create_daily_pack(today_utc)
            logger.info("Today's feed is pre-warmed and ready in cache.")
        except Exception as e:
            logger.warning("Startup pre-warm encountered an error (will retry on demand): %r", e)

        # Enforce retention on boot
        await self.prune_expired_packs(today_utc)

    def start(self) -> None:
        """Starts the scheduler and launches the startup pre-warming task."""
        # Schedule midnight UTC trigger every day at 00:00
        self.scheduler.add_job(
            self._daily_midnight_job,
            trigger=CronTrigger(hour=0, minute=0, timezone=timezone.utc),
            id="daily_midnight_feed_aggregation",
            replace_existing=True,
            misfire_grace_time=3600,
        )
        self.scheduler.start()
        logger.info("AsyncIOScheduler started with 00:00 UTC cron.")

        # Trigger background startup pre-warm task without blocking server boot
        self._prewarm_task = asyncio.create_task(self._prewarm_on_startup())

    async def stop(self) -> None:
        """Cleanly shuts down scheduler."""
        if self._prewarm_task and not self._prewarm_task.done():
            self._prewarm_task.cancel()
        if self.scheduler.running:
            self.scheduler.shutdown(wait=False)
            logger.info("AsyncIOScheduler shut down.")

feed_scheduler = FeedScheduler()
