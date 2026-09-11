from typing import Optional
import httpx
from app.core.config import settings


class HTTPClientManager:
    """Manages the lifecycle of a shared httpx.AsyncClient instance."""
    _client: Optional[httpx.AsyncClient] = None

    @classmethod
    def start_client(cls) -> httpx.AsyncClient:
        """Initialize the shared httpx.AsyncClient with connection pooling and timeouts."""
        if cls._client is None or cls._client.is_closed:
            limits = httpx.Limits(max_connections=100, max_keepalive_connections=20)
            timeout = httpx.Timeout(getattr(settings, "HTTP_TIMEOUT_SECONDS", 10.0), connect=5.0)
            headers = {
                "User-Agent": "CuriosityDaily/1.0 (https://curiositydaily.example.com; contact@curiositydaily.example.com)",
                "Accept": "application/json, text/plain, */*",
            }
            cls._client = httpx.AsyncClient(
                limits=limits,
                timeout=timeout,
                headers=headers,
                follow_redirects=True,
            )
        return cls._client

    @classmethod
    async def stop_client(cls) -> None:
        """Gracefully close the shared httpx.AsyncClient."""
        if cls._client is not None and not cls._client.is_closed:
            await cls._client.aclose()
            cls._client = None

    @classmethod
    def get_client(cls) -> httpx.AsyncClient:
        """Get the active httpx.AsyncClient, initializing if not present."""
        if cls._client is None or cls._client.is_closed:
            return cls.start_client()
        return cls._client


# Convenient module-level aliases
start_client = HTTPClientManager.start_client
stop_client = HTTPClientManager.stop_client
get_http_client = HTTPClientManager.get_client
