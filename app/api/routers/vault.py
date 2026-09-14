import math
from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.models.domain import DailyPack
from app.schemas.discovery import VaultHistoryItem, VaultHistoryResponse

router = APIRouter(prefix="/api/v1/vault", tags=["The Vault & History"])


@router.get("/history", response_model=List[VaultHistoryItem], summary="Chronological 30-Day Archive History for The Vault")
async def get_vault_history(
    limit: int = Query(30, ge=1, le=30, description="Max archive records (capped at strict 30-day window)"),
    db: AsyncSession = Depends(get_db),
) -> List[VaultHistoryItem]:
    """
    Returns the past 30 days of archived packs with hero thumbnails and article previews.
    Powers the chronological magazine-style timeline in The Vault without pagination envelopes.
    """
    data_stmt = (
        select(DailyPack)
        .order_by(DailyPack.pack_date.desc())
        .limit(limit)
    )
    result = await db.execute(data_stmt)
    packs = result.scalars().all()

    items: List[VaultHistoryItem] = []
    for pack in packs:
        # Find first valid hero thumbnail among articles or cosmos
        hero_thumb: Optional[str] = None
        for art in pack.articles_json:
            if isinstance(art, dict) and art.get("thumbnail_url"):
                hero_thumb = art["thumbnail_url"]
                break

        if not hero_thumb:
            for cos in pack.cosmos_json:
                if isinstance(cos, dict) and cos.get("url"):
                    hero_thumb = cos["url"]
                    break

        # Extract article titles
        article_titles: List[str] = []
        for art in pack.articles_json:
            if isinstance(art, dict):
                title = art.get("normalized_title") or art.get("title")
                if title:
                    article_titles.append(title)

        # Fact preview snippet
        fact_preview: Optional[str] = None
        if pack.facts_json and isinstance(pack.facts_json, list):
            first_fact = pack.facts_json[0]
            if isinstance(first_fact, dict):
                fact_preview = first_fact.get("text")

        items.append(
            VaultHistoryItem(
                pack_date=pack.pack_date,
                hero_thumbnail_url=hero_thumb,
                article_titles=article_titles,
                fact_preview=fact_preview,
                created_at=pack.created_at,
            )
        )

    return items
