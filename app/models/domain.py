import uuid
from datetime import date, datetime
from sqlalchemy import Date, DateTime, JSON, Uuid, func
from sqlalchemy.dialects.postgresql import JSONB, UUID as PG_UUID
from sqlalchemy.orm import Mapped, mapped_column
from app.models.base import Base

class DailyPack(Base):
    __tablename__ = "daily_packs"

    # Dialect-agnostic UUID: renders as native UUID on PostgreSQL, and CHAR(32)/BLOB on SQLite
    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True).with_variant(PG_UUID(as_uuid=True), "postgresql"),
        primary_key=True,
        default=uuid.uuid4
    )

    # Represents the specific day this pack belongs to
    pack_date: Mapped[date] = mapped_column(Date, unique=True, index=True, nullable=False)

    # JSON/JSONB columns: renders as native JSONB on PostgreSQL, and standard JSON on SQLite
    articles_json: Mapped[dict] = mapped_column(
        JSON().with_variant(JSONB, "postgresql"), nullable=False, default=list
    )
    quizzes_json: Mapped[dict] = mapped_column(
        JSON().with_variant(JSONB, "postgresql"), nullable=False, default=list
    )
    cosmos_json: Mapped[dict] = mapped_column(
        JSON().with_variant(JSONB, "postgresql"), nullable=False, default=list
    )
    facts_json: Mapped[dict] = mapped_column(
        JSON().with_variant(JSONB, "postgresql"), nullable=False, default=list
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
