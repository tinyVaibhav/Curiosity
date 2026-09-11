import json
import logging
import time
from typing import Any, Optional
import redis.asyncio as aioredis
from app.core.config import settings

logger = logging.getLogger("curiosity.cache")

class InMemoryTTLCache:
    """Thread-safe in-memory cache with TTL support for local development without Redis."""
    def __init__(self):
        self._store: dict[str, tuple[str, float]] = {}

    async def get(self, key: str) -> Optional[str]:
        item = self._store.get(key)
        if item is None:
            return None
        val, expiry = item
        if time.time() > expiry:
            del self._store[key]
            return None
        return val

    async def set(self, key: str, value: str, ex: Optional[int] = None) -> None:
        expiry = time.time() + (ex if ex is not None else 86400)
        self._store[key] = (value, expiry)

    async def delete(self, key: str) -> None:
        self._store.pop(key, None)

    async def close(self) -> None:
        self._store.clear()

class CacheManager:
    def __init__(self):
        self.redis_client: Optional[aioredis.Redis] = None
        self.memory_cache: Optional[InMemoryTTLCache] = None
        self.is_using_memory: bool = False

    async def initialize(self) -> None:
        """Connects to Redis or falls back to in-memory cache if Redis is unavailable."""
        try:
            client = aioredis.from_url(
                settings.REDIS_URL,
                decode_responses=True,
                socket_connect_timeout=1.5
            )
            await client.ping()
            self.redis_client = client
            self.is_using_memory = False
            logger.info("Connected successfully to Redis.")
        except Exception as e:
            if settings.AUTO_FALLBACK_CACHE:
                logger.warning(
                    f"Could not connect to Redis at {settings.REDIS_URL} ({e}). "
                    "Falling back to in-memory TTL cache for local testing."
                )
                self.memory_cache = InMemoryTTLCache()
                self.is_using_memory = True
            else:
                raise e

    async def get_json(self, key: str) -> Optional[dict[str, Any]]:
        """Retrieves and deserializes JSON from cache."""
        try:
            raw: Optional[str] = None
            if self.is_using_memory and self.memory_cache:
                raw = await self.memory_cache.get(key)
            elif self.redis_client:
                raw = await self.redis_client.get(key)
            
            if raw:
                return json.loads(raw)
            return None
        except Exception as err:
            logger.error(f"Error reading cache key '{key}': {err}")
            return None

    async def set_json(self, key: str, value: Any, expire_seconds: Optional[int] = None) -> bool:
        """Serializes and saves data to cache with TTL."""
        ttl = expire_seconds if expire_seconds is not None else settings.CACHE_TTL_SECONDS
        try:
            raw = json.dumps(value, default=str)
            if self.is_using_memory and self.memory_cache:
                await self.memory_cache.set(key, raw, ex=ttl)
            elif self.redis_client:
                await self.redis_client.set(key, raw, ex=ttl)
            return True
        except Exception as err:
            logger.error(f"Error setting cache key '{key}': {err}")
            return False

    async def close(self) -> None:
        """Closes Redis or memory cache connections."""
        if self.redis_client:
            await self.redis_client.aclose()
            self.redis_client = None
        if self.memory_cache:
            await self.memory_cache.close()
            self.memory_cache = None

cache_manager = CacheManager()
