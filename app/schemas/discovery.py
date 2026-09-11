from datetime import date, datetime
from enum import Enum
from typing import List, Optional
from pydantic import BaseModel, Field


class TopicEnum(str, Enum):
    SPACE = "SPACE"
    HISTORY = "HISTORY"
    BIOLOGY = "BIOLOGY"
    TECH = "TECH"


class VaultHistoryItem(BaseModel):
    """Rich summary card representing a past day's pack in The Vault."""
    pack_date: date = Field(..., description="The calendar date of the archived pack")
    hero_thumbnail_url: Optional[str] = Field(None, description="Hero image thumbnail from that day's articles")
    article_titles: List[str] = Field(default_factory=list, description="Titles of the 3 featured articles")
    fact_preview: Optional[str] = Field(None, description="A preview snippet of one of the day's facts")
    created_at: Optional[datetime] = Field(None, description="Timestamp when the pack was archived")


class VaultHistoryResponse(BaseModel):
    """Paginated response for The Vault archive timeline."""
    items: List[VaultHistoryItem]
    total: int
    page: int
    page_size: int
    total_pages: int
