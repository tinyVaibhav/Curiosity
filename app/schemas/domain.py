from datetime import date, datetime
from typing import List, Optional
import uuid
from pydantic import BaseModel, ConfigDict, Field


class ArticleItem(BaseModel):
    """Article item schema sourced from Wikipedia TFA (Today's Featured Article)."""
    title: str = Field(..., description="Canonical or raw title of the article")
    normalized_title: str = Field(..., description="Human-friendly cleaned title")
    summary: str = Field(..., description="Short summary/extract of the article")
    thumbnail_url: Optional[str] = Field(default=None, description="URL to the article thumbnail image")

    model_config = ConfigDict(from_attributes=True)


class QuizItem(BaseModel):
    """Quiz trivia item schema sourced from OpenTDB."""
    question: str = Field(..., description="The quiz question text")
    correct_answer: str = Field(..., description="The correct answer choice")
    incorrect_answers: List[str] = Field(..., description="List of incorrect answer options")

    model_config = ConfigDict(from_attributes=True)


class CosmosItem(BaseModel):
    """Astronomy item schema sourced from NASA APOD."""
    title: str = Field(..., description="Title of the astronomical picture/feature")
    explanation: str = Field(..., description="Educational explanation of the celestial object or event")
    url: str = Field(..., description="URL to the image or video")

    model_config = ConfigDict(from_attributes=True)


class FactItem(BaseModel):
    """Bite-sized fact item schema sourced from various trivia and history APIs."""
    text: str = Field(..., description="The fact statement text")
    source: str = Field(..., description="Source identifier (e.g. Useless Facts, Numbers API, On This Day)")

    model_config = ConfigDict(from_attributes=True)


class DailyPackSchema(BaseModel):
    """Unified daily payload containing 15 curated educational items."""
    id: Optional[uuid.UUID] = Field(default=None, description="Unique identifier for the persisted daily pack")
    pack_date: date = Field(default_factory=date.today, description="The date this daily pack represents")
    articles: List[ArticleItem] = Field(..., min_length=3, max_length=3, description="3 curated featured articles")
    quizzes: List[QuizItem] = Field(..., min_length=3, max_length=3, description="3 trivia quiz items")
    cosmos: List[CosmosItem] = Field(..., min_length=3, max_length=3, description="3 astronomy items")
    facts: List[FactItem] = Field(..., min_length=6, max_length=6, description="6 bite-sized facts")
    created_at: Optional[datetime] = Field(default=None, description="Timestamp when the pack was generated/stored")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)
