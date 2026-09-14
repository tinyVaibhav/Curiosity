from datetime import date, datetime, timezone
import hashlib
import hmac
import logging
import time
from typing import Optional

from fastapi import APIRouter, Depends, Header, HTTPException, Query, Request, status
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.database import get_db
from app.core.http_client import get_http_client
from app.core.scheduler import feed_scheduler
from app.services.feed_service import FeedService

logger = logging.getLogger("curiosity.cron")

router = APIRouter(prefix="/api/v1/cron", tags=["Cron Automation"])


class CreateScheduleRequest(BaseModel):
    target_url: Optional[str] = Field(
        default=None,
        description="Destination URL for the daily pack webhook (e.g. https://my-app.onrender.com/api/v1/cron/daily-pack). If omitted, uses PUBLIC_BASE_URL or request base URL.",
    )
    cron_expression: str = Field(
        default="0 0 * * *",
        description="Cron expression for scheduling (defaults to 00:00 UTC daily).",
    )
    retries: int = Field(
        default=3,
        description="Number of retries QStash should attempt if delivery fails.",
    )
    qstash_token: Optional[str] = Field(
        default=None,
        description="Upstash QStash token. If omitted, uses QSTASH_TOKEN from environment (.env).",
    )


def _verify_cron_authorization(
    authorization: Optional[str] = Header(None),
    x_cron_secret: Optional[str] = Header(None, alias="X-Cron-Secret"),
    upstash_signature: Optional[str] = Header(None, alias="Upstash-Signature"),
) -> bool:
    """
    Verifies that the incoming webhook request is authorized by:
    1. Authorization Bearer token matching settings.CRON_SECRET, OR
    2. X-Cron-Secret header matching settings.CRON_SECRET, OR
    3. Upstash-Signature header if QStash signing keys are configured.
    """
    expected_secret = settings.CRON_SECRET

    # Check 1: Bearer token
    if authorization:
        parts = authorization.split(" ")
        if len(parts) == 2 and parts[0].lower() == "bearer":
            if hmac.compare_digest(parts[1].strip(), expected_secret):
                return True

    # Check 2: Direct custom secret header
    if x_cron_secret and hmac.compare_digest(x_cron_secret.strip(), expected_secret):
        return True

    # Check 3: Upstash QStash native signature (if keys configured)
    if upstash_signature and (settings.QSTASH_CURRENT_SIGNING_KEY or settings.QSTASH_NEXT_SIGNING_KEY):
        # Basic check that signature header is provided when key is configured
        # Full token validation can match current or next keys
        keys_to_check = [k for k in [settings.QSTASH_CURRENT_SIGNING_KEY, settings.QSTASH_NEXT_SIGNING_KEY] if k]
        for key in keys_to_check:
            if hmac.compare_digest(upstash_signature.strip(), key):
                return True

    return False


@router.post(
    "/daily-pack",
    summary="Trigger Midnight Feed Aggregation & Retention Pruning (Upstash QStash Webhook)",
    status_code=status.HTTP_200_OK,
)
async def trigger_daily_pack_cron(
    request: Request,
    date_param: Optional[date] = Query(
        default=None,
        alias="date",
        description="Optional date to aggregate for (defaults to UTC today). Format: YYYY-MM-DD",
    ),
    db: AsyncSession = Depends(get_db),
    authorization: Optional[str] = Header(None),
    x_cron_secret: Optional[str] = Header(None, alias="X-Cron-Secret"),
    upstash_signature: Optional[str] = Header(None, alias="Upstash-Signature"),
):
    """
    Webhook endpoint invoked automatically by Upstash QStash (or any external scheduler)
    at 00:00 UTC to:
    1. Pre-aggregate and cache the 15-item Daily Pack for the new calendar day.
    2. Purge historical packs older than 30 days.
    """
    if not _verify_cron_authorization(authorization, x_cron_secret, upstash_signature):
        logger.warning("Unauthorized attempt to access /api/v1/cron/daily-pack from %s", request.client)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Unauthorized: Invalid cron secret or Upstash signature.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    start_time = time.time()
    target_date = date_param or datetime.now(timezone.utc).date()
    logger.info("Executing QStash cron aggregation for date %s", target_date)

    try:
        # 1. Generate / Cache Daily Pack
        pack = await FeedService.get_or_create_daily_pack(target_date=target_date, db=db)

        # 2. Prune packs older than 30 days
        pruned_count = await feed_scheduler.prune_expired_packs(reference_date=target_date)

        elapsed_ms = int((time.time() - start_time) * 1000)

        logger.info(
            "QStash cron completed successfully for %s in %d ms (pruned: %d)",
            target_date,
            elapsed_ms,
            pruned_count,
        )

        return {
            "status": "success",
            "message": "Daily pack aggregated and cached successfully.",
            "pack_date": target_date.isoformat(),
            "items_summary": {
                "articles": len(pack.articles),
                "quizzes": len(pack.quizzes),
                "cosmos": len(pack.cosmos),
                "facts": len(pack.facts),
            },
            "pruned_expired_packs": pruned_count,
            "execution_time_ms": elapsed_ms,
        }

    except Exception as exc:
        logger.error("Error during QStash cron execution for %s: %r", target_date, exc, exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Cron aggregation failed: {exc}",
        )


def get_qstash_base_url() -> str:
    """Returns the regional or global QStash REST API base URL."""
    if settings.PUBLIC_BASE_URL and "qstash" in settings.PUBLIC_BASE_URL:
        return settings.PUBLIC_BASE_URL.rstrip("/")
    if settings.QSTASH_URL:
        return settings.QSTASH_URL.rstrip("/")
    return "https://qstash.upstash.io"


@router.post(
    "/setup-schedule",
    summary="Create or update an Upstash QStash Cron Schedule programmatically",
    status_code=status.HTTP_200_OK,
)
async def setup_qstash_schedule(
    request: Request,
    payload: CreateScheduleRequest = CreateScheduleRequest(),
    authorization: Optional[str] = Header(None),
    x_cron_secret: Optional[str] = Header(None, alias="X-Cron-Secret"),
):
    """
    Programmatically creates or updates a recurring cron schedule on Upstash QStash.
    Ensures that Upstash forwards the Authorization: Bearer <CRON_SECRET> header
    to the target endpoint so the midnight aggregation runs securely.
    """
    if not _verify_cron_authorization(authorization, x_cron_secret):
        logger.warning("Unauthorized attempt to access /api/v1/cron/setup-schedule from %s", request.client)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Unauthorized: Valid CRON_SECRET is required to configure QStash schedules.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = (payload.qstash_token or settings.QSTASH_TOKEN or "").strip()
    if not token:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Missing QStash Token. Please set QSTASH_TOKEN in your .env or provide 'qstash_token' in the request body.",
        )

    # Determine destination webhook URL (target backend receiving the cron ping)
    if payload.target_url:
        destination = payload.target_url.strip()
    elif settings.PUBLIC_BASE_URL and "qstash" not in settings.PUBLIC_BASE_URL:
        destination = f"{settings.PUBLIC_BASE_URL.rstrip('/')}/api/v1/cron/daily-pack"
    else:
        destination = f"{str(request.base_url).rstrip('/')}/api/v1/cron/daily-pack"

    qstash_base = get_qstash_base_url()
    qstash_api_url = f"{qstash_base}/v2/schedules/{destination}"

    headers = {
        "Authorization": f"Bearer {token}",
        "Upstash-Cron": payload.cron_expression,
        "Upstash-Retries": str(payload.retries),
        "Upstash-Forward-Authorization": f"Bearer {settings.CRON_SECRET}",
        "Content-Type": "application/json",
    }

    client = get_http_client()
    try:
        resp = await client.post(
            qstash_api_url,
            headers=headers,
            json={"source": "curiosity_backend_auto_setup"},
        )
        if resp.status_code not in (200, 201):
            logger.error("Upstash QStash API error (%d): %s", resp.status_code, resp.text)
            raise HTTPException(
                status_code=resp.status_code,
                detail=f"Upstash QStash API returned error ({resp.status_code}): {resp.text}",
            )

        data = resp.json()
        logger.info(
            "Successfully configured QStash schedule for destination: %s (ID: %s)",
            destination,
            data.get("scheduleId"),
        )
        return {
            "status": "success",
            "message": "Upstash QStash cron schedule configured successfully.",
            "schedule_id": data.get("scheduleId"),
            "destination": destination,
            "cron_expression": payload.cron_expression,
            "retries": payload.retries,
        }
    except HTTPException:
        raise
    except Exception as err:
        logger.error("Failed to communicate with Upstash QStash API: %r", err)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Failed to communicate with Upstash QStash API: {err}",
        )


@router.get(
    "/schedules",
    summary="List all active Upstash QStash schedules",
    status_code=status.HTTP_200_OK,
)
async def list_qstash_schedules(
    request: Request,
    authorization: Optional[str] = Header(None),
    x_cron_secret: Optional[str] = Header(None, alias="X-Cron-Secret"),
    qstash_token: Optional[str] = Query(None, description="Optional override for QStash token"),
):
    """Lists all active cron schedules configured in your Upstash QStash account."""
    if not _verify_cron_authorization(authorization, x_cron_secret):
        logger.warning("Unauthorized attempt to access /api/v1/cron/schedules from %s", request.client)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Unauthorized: Valid CRON_SECRET is required to view QStash schedules.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = (qstash_token or settings.QSTASH_TOKEN or "").strip()
    if not token:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Missing QStash Token. Set QSTASH_TOKEN in .env or pass ?qstash_token=...",
        )

    client = get_http_client()
    qstash_base = get_qstash_base_url()
    try:
        resp = await client.get(
            f"{qstash_base}/v2/schedules",
            headers={"Authorization": f"Bearer {token}"},
        )
        if resp.status_code != 200:
            raise HTTPException(
                status_code=resp.status_code,
                detail=f"QStash API returned error: {resp.text}",
            )
        return resp.json()
    except HTTPException:
        raise
    except Exception as err:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Failed to list schedules: {err}",
        )


@router.delete(
    "/schedules/{schedule_id}",
    summary="Delete an Upstash QStash schedule by ID",
    status_code=status.HTTP_200_OK,
)
async def delete_qstash_schedule(
    schedule_id: str,
    request: Request,
    authorization: Optional[str] = Header(None),
    x_cron_secret: Optional[str] = Header(None, alias="X-Cron-Secret"),
    qstash_token: Optional[str] = Query(None, description="Optional override for QStash token"),
):
    """Removes an active schedule from Upstash QStash by its schedule ID."""
    if not _verify_cron_authorization(authorization, x_cron_secret):
        logger.warning("Unauthorized attempt to access /api/v1/cron/schedules/%s from %s", schedule_id, request.client)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Unauthorized: Valid CRON_SECRET is required to delete QStash schedules.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = (qstash_token or settings.QSTASH_TOKEN or "").strip()
    if not token:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Missing QStash Token. Set QSTASH_TOKEN in .env or pass ?qstash_token=...",
        )

    client = get_http_client()
    qstash_base = get_qstash_base_url()
    try:
        resp = await client.delete(
            f"{qstash_base}/v2/schedules/{schedule_id}",
            headers={"Authorization": f"Bearer {token}"},
        )
        if resp.status_code not in (200, 204):
            raise HTTPException(
                status_code=resp.status_code,
                detail=f"QStash API returned error: {resp.text}",
            )
        return {
            "status": "success",
            "message": f"Schedule '{schedule_id}' deleted successfully.",
        }
    except HTTPException:
        raise
    except Exception as err:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Failed to delete schedule: {err}",
        )

