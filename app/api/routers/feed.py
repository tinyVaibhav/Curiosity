from datetime import date, datetime, timezone
from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.schemas.domain import DailyPackSchema
from app.services.feed_service import FeedService

router = APIRouter(prefix="/api/v1/feed", tags=["Daily Feed"])

from urllib.parse import quote


def _sanitize_pack_image_urls(pack: DailyPackSchema) -> DailyPackSchema:
    """Passes through clean canonical image URLs so frontend clients resolve platform-specific proxy endpoints dynamically."""
    return pack


@router.get("/today", response_model=DailyPackSchema, summary="Get Today's Educational Feed")
async def get_today_feed(
    date: Optional[date] = Query(
        default=None,
        description="Optional client-local date (YYYY-MM-DD). If omitted, defaults to UTC today.",
    ),
    db: AsyncSession = Depends(get_db),
) -> DailyPackSchema:
    """
    Returns the curated 15-item payload for today.
    Serves from Redis/cache in sub-milliseconds on hit, or generates on-demand on first request.
    """
    target_date = date or datetime.now(timezone.utc).date()
    pack = await FeedService.get_or_create_daily_pack(target_date=target_date, db=db)
    return _sanitize_pack_image_urls(pack)


@router.get("/archive", response_model=DailyPackSchema, summary="Get Historical Feed for a Specific Date")
async def get_archive_feed(
    date: date = Query(..., description="The archive date to retrieve (YYYY-MM-DD)"),
    db: AsyncSession = Depends(get_db),
) -> DailyPackSchema:
    """
    Retrieves a past daily feed from The Vault.
    Generates and persists on-demand if the date was not previously pre-computed.
    """
    pack = await FeedService.get_or_create_daily_pack(target_date=date, db=db)
    return _sanitize_pack_image_urls(pack)

@router.get("/archive/dates", response_model=List[date], summary="List All Stored Archive Dates")
async def list_archived_dates(
    db: AsyncSession = Depends(get_db),
) -> List[date]:
    """Returns a list of all dates currently stored in The Vault."""
    return await FeedService.get_archived_dates(db=db)


import time
import logging
from fastapi import HTTPException, Response

logger = logging.getLogger("curiosity.image_proxy")
_image_cache: dict[str, tuple[bytes, str, float]] = {}


@router.get("/proxy-image", summary="Proxy external image with CORS headers")
async def proxy_image(url: str = Query(..., description="Target image URL to proxy")):
    """
    Proxies external images (like NASA APOD or Wikimedia) to provide proper CORS headers
    and fast in-memory caching for web clients (e.g. Flutter Web CanvasKit).
    """
    if not (url.startswith("http://") or url.startswith("https://")):
        raise HTTPException(status_code=400, detail="Invalid URL scheme")

    now = time.time()
    if url in _image_cache:
        content, content_type, expiry = _image_cache[url]
        if now < expiry:
            return Response(
                content=content,
                media_type=content_type,
                headers={
                    "Cache-Control": "public, max-age=86400",
                    "Access-Control-Allow-Origin": "*",
                },
            )
        else:
            _image_cache.pop(url, None)

    from app.core.http_client import get_http_client
    client = get_http_client()
    try:
        resp = await client.get(url, timeout=15.0)
        if resp.status_code != 200:
            logger.warning("Upstream image fetch failed with status %d for %s", resp.status_code, url)
            raise HTTPException(status_code=resp.status_code, detail="Failed to fetch upstream image")

        content_type = resp.headers.get("content-type", "image/jpeg")
        if len(_image_cache) > 200:
            for k in list(_image_cache.keys())[:50]:
                _image_cache.pop(k, None)

        _image_cache[url] = (resp.content, content_type, now + 86400)

        return Response(
            content=resp.content,
            media_type=content_type,
            headers={
                "Cache-Control": "public, max-age=86400",
                "Access-Control-Allow-Origin": "*",
            },
        )
    except HTTPException:
        raise
    except Exception as exc:
        logger.error("Error proxying image %s: %r", url, exc)
        raise HTTPException(status_code=502, detail=f"Image proxy error: {exc}")

