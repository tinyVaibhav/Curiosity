import asyncio
from datetime import date, timedelta
import html
import logging
import random
from typing import List, Optional

from app.core.config import settings
from app.core.http_client import get_http_client
from app.schemas.domain import (
    ArticleItem,
    CosmosItem,
    DailyPackSchema,
    FactItem,
    QuizItem,
)

logger = logging.getLogger(__name__)

# ==============================================================================
# EVERGREEN FALLBACK DATA
# Guaranteed high-quality content used during network timeouts or upstream outages
# ==============================================================================

EVERGREEN_ARTICLES: List[ArticleItem] = [
    ArticleItem(
        title="James_Webb_Space_Telescope",
        normalized_title="James Webb Space Telescope",
        summary=(
            "The James Webb Space Telescope is an infrared astronomy space observatory. "
            "It conducts high-resolution infrared observations to view older, more distant, "
            "or fainter celestial objects than its predecessor, the Hubble Space Telescope."
        ),
        thumbnail_url="https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/James_Webb_Space_Telescope_Mirror.jpg/320px-James_Webb_Space_Telescope_Mirror.jpg",
    ),
    ArticleItem(
        title="Rosetta_(spacecraft)",
        normalized_title="Rosetta (spacecraft)",
        summary=(
            "Rosetta was a space probe built by the European Space Agency which performed a "
            "detailed study of comet 67P/Churyumov–Gerasimenko, performing the first successful "
            "soft landing of a lander module on a comet nucleus."
        ),
        thumbnail_url="https://upload.wikimedia.org/wikipedia/commons/thumb/9/96/Rosetta_spacecraft_model.png/320px-Rosetta_spacecraft_model.png",
    ),
    ArticleItem(
        title="Great_Barrier_Reef",
        normalized_title="Great Barrier Reef",
        summary=(
            "The Great Barrier Reef is the world's largest coral reef system composed of over "
            "2,900 individual reefs and 900 islands stretching for over 2,300 kilometres over "
            "an area of approximately 344,400 square kilometres."
        ),
        thumbnail_url="https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/GreatBarrierReef-sand-cays.jpg/320px-GreatBarrierReef-sand-cays.jpg",
    ),
]

EVERGREEN_QUIZZES: List[QuizItem] = [
    QuizItem(
        question="What is the powerhouse of the biological cell responsible for producing ATP?",
        correct_answer="Mitochondria",
        incorrect_answers=["Ribosome", "Nucleus", "Endoplasmic Reticulum"],
    ),
    QuizItem(
        question="Which planet in our Solar System has the greatest number of confirmed moons?",
        correct_answer="Saturn",
        incorrect_answers=["Jupiter", "Mars", "Neptune"],
    ),
    QuizItem(
        question="What element does the chemical symbol 'Au' represent on the periodic table?",
        correct_answer="Gold",
        incorrect_answers=["Silver", "Argon", "Aluminum"],
    ),
]

EVERGREEN_COSMOS: List[CosmosItem] = [
    CosmosItem(
        title="The Pillars of Creation",
        explanation=(
            "A celestial landscape of interstellar gas and dust located in the Eagle Nebula, "
            "photographed by the Hubble and James Webb Space Telescopes, where active star formation occurs."
        ),
        url="https://apod.nasa.gov/apod/image/2210/PillarsOfCreation_Webb_960.jpg",
    ),
    CosmosItem(
        title="The Andromeda Galaxy",
        explanation=(
            "The Andromeda Galaxy (M31) is the nearest major barred spiral galaxy to the Milky Way, "
            "spanning approximately 220,000 light-years across and containing an estimated one trillion stars."
        ),
        url="https://apod.nasa.gov/apod/image/2108/M31_HubbleSubaruGendler_960.jpg",
    ),
    CosmosItem(
        title="The Pale Blue Dot",
        explanation=(
            "A photograph of planet Earth captured on February 14, 1990, by the Voyager 1 space probe "
            "from a record distance of roughly 6 billion kilometers as part of that mission's Family Portrait series."
        ),
        url="https://apod.nasa.gov/apod/image/2002/PaleBlueDot_Voyager1_960.jpg",
    ),
]

EVERGREEN_USELESS_FACTS: List[FactItem] = [
    FactItem(
        text="Honey never spoils; archaeologists have excavated 3,000-year-old honey from ancient Egyptian tombs that remains fully edible.",
        source="Useless Facts (Fallback)",
    ),
    FactItem(
        text="Octopuses possess three hearts, nine brains, and circulate hemocyanin-rich blue blood throughout their bodies.",
        source="Useless Facts (Fallback)",
    ),
]

EVERGREEN_NUMBER_FACTS: List[FactItem] = [
    FactItem(
        text="42 is the precise angle in degrees at which light reflects through water droplets to form a primary rainbow.",
        source="Numbers API (Fallback)",
    ),
    FactItem(
        text="73 is the 21st prime number; its mirror 37 is the 12th prime number, whose mirror 21 is the product of 7 and 3.",
        source="Numbers API (Fallback)",
    ),
]

EVERGREEN_HISTORICAL_FACTS: List[FactItem] = [
    FactItem(
        text="In 1969: The Apollo 11 Lunar Module touched down on the lunar surface, marking humanity's first steps on another world.",
        source="Wikipedia (On This Day Fallback)",
    ),
    FactItem(
        text="In 1928: Sir Alexander Fleming discovered the antibacterial properties of penicillin at St Mary's Hospital, launching the antibiotic era.",
        source="Wikipedia (On This Day Fallback)",
    ),
]


class AggregatorService:
    """Non-blocking service that concurrently fetches and curates daily educational items."""

    @classmethod
    async def fetch_articles(cls, target_date: Optional[date] = None) -> List[ArticleItem]:
        """
        Fetch 3 featured articles from Wikipedia's TFA (Today's Featured Article) endpoint.
        Implements a Date-Seeded Randomizer:
        Seeds a pseudo-random generator with the target date to deterministically pick
        2 random past dates alongside today's featured article.
        """
        d = target_date or date.today()
        # Seed deterministic pseudo-random generator for this date
        rng = random.Random(d.isoformat())
        # Pick 2 distinct past date offsets (between 1 and 1500 days ago)
        past_offsets = rng.sample(range(1, 1500), 2)
        dates_to_fetch = [d, d - timedelta(days=past_offsets[0]), d - timedelta(days=past_offsets[1])]

        client = get_http_client()

        async def _fetch_single_article(article_date: date) -> Optional[ArticleItem]:
            url = f"https://en.wikipedia.org/api/rest_v1/feed/featured/{article_date.year}/{article_date.month:02d}/{article_date.day:02d}"
            try:
                response = await client.get(url)
                if response.status_code == 200:
                    data = response.json()
                    tfa = data.get("tfa")
                    if tfa:
                        raw_title = tfa.get("title", "")
                        norm_title = (
                            tfa.get("normalizedtitle")
                            or tfa.get("titles", {}).get("normalized")
                            or raw_title.replace("_", " ")
                        )
                        summary = tfa.get("extract") or tfa.get("description", "")
                        thumbnail_url = None
                        thumbnail_obj = tfa.get("thumbnail")
                        if isinstance(thumbnail_obj, dict):
                            thumbnail_url = thumbnail_obj.get("source")

                        if norm_title and summary:
                            return ArticleItem(
                                title=raw_title or norm_title,
                                normalized_title=norm_title,
                                summary=summary,
                                thumbnail_url=thumbnail_url,
                            )
                else:
                    logger.warning(
                        "Wikipedia TFA fetch for %s returned status %s", article_date, response.status_code
                    )
            except Exception as exc:
                logger.warning("Error fetching Wikipedia TFA for %s: %r", article_date, exc)
            return None

        tasks = [_fetch_single_article(dt) for dt in dates_to_fetch]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        articles: List[ArticleItem] = []
        for r in results:
            if isinstance(r, ArticleItem):
                # Avoid duplicate articles
                if not any(a.title == r.title for a in articles):
                    articles.append(r)

        # Backfill with evergreen articles if any call failed or returned empty
        if len(articles) < 3:
            for fallback in EVERGREEN_ARTICLES:
                if not any(a.title == fallback.title for a in articles):
                    articles.append(fallback)
                if len(articles) == 3:
                    break

        return articles[:3]

    @classmethod
    async def fetch_quizzes(cls) -> List[QuizItem]:
        """
        Fetch 3 multiple-choice trivia quiz items from OpenTDB.
        Unescapes HTML entity encodings and backfills with evergreen quizzes if upstream fails.
        """
        client = get_http_client()
        url = "https://opentdb.com/api.php?amount=3&type=multiple"
        quizzes: List[QuizItem] = []

        try:
            response = await client.get(url)
            if response.status_code == 200:
                data = response.json()
                if data.get("response_code") == 0:
                    for item in data.get("results", []):
                        raw_q = item.get("question", "")
                        raw_correct = item.get("correct_answer", "")
                        raw_incorrect = item.get("incorrect_answers", [])

                        if raw_q and raw_correct and raw_incorrect:
                            q_text = html.unescape(raw_q).strip()
                            correct_ans = html.unescape(raw_correct).strip()
                            incorrect_ans = [html.unescape(ans).strip() for ans in raw_incorrect]
                            quizzes.append(
                                QuizItem(
                                    question=q_text,
                                    correct_answer=correct_ans,
                                    incorrect_answers=incorrect_ans,
                                )
                            )
                else:
                    logger.warning("OpenTDB returned non-zero response_code: %s", data.get("response_code"))
            else:
                logger.warning("OpenTDB request failed with status: %s", response.status_code)
        except Exception as exc:
            logger.warning("Error fetching quizzes from OpenTDB: %r", exc)

        # Backfill with evergreen quizzes if needed
        if len(quizzes) < 3:
            for fallback in EVERGREEN_QUIZZES:
                if not any(q.question == fallback.question for q in quizzes):
                    quizzes.append(fallback)
                if len(quizzes) == 3:
                    break

        return quizzes[:3]

    @classmethod
    async def fetch_cosmos(cls) -> List[CosmosItem]:
        """
        Fetch 3 astronomy items from NASA's Astronomy Picture of the Day (APOD) API.
        Triggers two parallel calls:
        1. Today's APOD
        2. 2 Random APODs (count=2)
        """
        client = get_http_client()
        api_key = getattr(settings, "NASA_API_KEY", "DEMO_KEY")
        base_url = "https://api.nasa.gov/planetary/apod"

        async def _fetch_today_apod() -> Optional[CosmosItem]:
            try:
                response = await client.get(f"{base_url}?api_key={api_key}")
                if response.status_code == 200:
                    data = response.json()
                    title = data.get("title")
                    explanation = data.get("explanation")
                    url = data.get("url") or data.get("hdurl")
                    if title and explanation and url:
                        return CosmosItem(title=title, explanation=explanation, url=url)
                else:
                    logger.warning("NASA APOD today call returned status %s", response.status_code)
            except Exception as exc:
                logger.warning("Error fetching NASA APOD today: %r", exc)
            return None

        async def _fetch_random_apods() -> List[CosmosItem]:
            items: List[CosmosItem] = []
            try:
                response = await client.get(f"{base_url}?api_key={api_key}&count=2")
                if response.status_code == 200:
                    data = response.json()
                    if isinstance(data, list):
                        for entry in data:
                            title = entry.get("title")
                            explanation = entry.get("explanation")
                            url = entry.get("url") or entry.get("hdurl")
                            if title and explanation and url:
                                items.append(CosmosItem(title=title, explanation=explanation, url=url))
                else:
                    logger.warning("NASA APOD random call returned status %s", response.status_code)
            except Exception as exc:
                logger.warning("Error fetching NASA APOD random: %r", exc)
            return items

        results = await asyncio.gather(_fetch_today_apod(), _fetch_random_apods(), return_exceptions=True)

        cosmos: List[CosmosItem] = []
        today_apod = results[0]
        if isinstance(today_apod, CosmosItem):
            cosmos.append(today_apod)

        random_apods = results[1]
        if isinstance(random_apods, list):
            for item in random_apods:
                if isinstance(item, CosmosItem) and not any(c.title == item.title for c in cosmos):
                    cosmos.append(item)

        # Backfill if NASA failed, rate-limited, or returned fewer than 3 items
        if len(cosmos) < 3:
            for fallback in EVERGREEN_COSMOS:
                if not any(c.title == fallback.title for c in cosmos):
                    cosmos.append(fallback)
                if len(cosmos) == 3:
                    break

        return cosmos[:3]

    @classmethod
    async def fetch_facts(cls, target_date: Optional[date] = None) -> List[FactItem]:
        """
        Fetch 6 bite-sized educational facts:
        - 2 Useless Facts (uselessfacts.jsph.pl)
        - 2 Number Facts (numbersapi.com)
        - 2 Historical Facts (Wikipedia onthisday feed)
        """
        d = target_date or date.today()
        client = get_http_client()

        # 1. Useless Facts (2 items)
        async def _fetch_single_useless_fact() -> Optional[FactItem]:
            try:
                response = await client.get("https://uselessfacts.jsph.pl/api/v2/facts/random")
                if response.status_code == 200:
                    data = response.json()
                    fact_text = data.get("text", "").strip()
                    if fact_text:
                        return FactItem(text=fact_text, source="Useless Facts")
                else:
                    logger.warning("Useless facts returned status %s", response.status_code)
            except Exception as exc:
                logger.warning("Error fetching useless fact: %r", exc)
            return None

        # 2. Number Facts (2 items, with live fallback)
        async def _fetch_single_number_fact() -> Optional[FactItem]:
            try:
                response = await client.get("http://numbersapi.com/random/trivia?json")
                if response.status_code == 200:
                    data = response.json()
                    fact_text = data.get("text", "").strip()
                    if fact_text:
                        return FactItem(text=fact_text, source="Numbers API")
            except Exception:
                pass
            try:
                response = await client.get("https://uselessfacts.jsph.pl/api/v2/facts/random")
                if response.status_code == 200:
                    data = response.json()
                    fact_text = data.get("text", "").strip()
                    if fact_text:
                        return FactItem(text=fact_text, source="Useless Facts")
            except Exception as exc:
                logger.warning("Error fetching fallback fact: %r", exc)
            return None

        # 3. Wikipedia On This Day (2 items)
        async def _fetch_historical_facts() -> List[FactItem]:
            hist_items: List[FactItem] = []
            url = f"https://en.wikipedia.org/api/rest_v1/feed/onthisday/selected/{d.month:02d}/{d.day:02d}"
            try:
                response = await client.get(url)
                if response.status_code == 200:
                    data = response.json()
                    selected = data.get("selected", [])
                    if selected:
                        hist_rng = random.Random(f"{d.isoformat()}-history")
                        sample_count = min(2, len(selected))
                        sampled = hist_rng.sample(selected, sample_count)
                        for item in sampled:
                            raw_text = item.get("text", "").strip()
                            year = item.get("year")
                            if raw_text:
                                prefix = f"In {year}: " if year is not None else ""
                                hist_items.append(
                                    FactItem(
                                        text=f"{prefix}{raw_text}",
                                        source="Wikipedia (On This Day)",
                                    )
                                )
                else:
                    logger.warning("Wikipedia onthisday returned status %s", response.status_code)
            except Exception as exc:
                logger.warning("Error fetching historical facts: %r", exc)
            return hist_items

        results = await asyncio.gather(
            _fetch_single_useless_fact(),
            _fetch_single_useless_fact(),
            _fetch_single_number_fact(),
            _fetch_single_number_fact(),
            _fetch_historical_facts(),
            return_exceptions=True,
        )

        useless_facts: List[FactItem] = []
        for res in results[:2]:
            if isinstance(res, FactItem):
                useless_facts.append(res)
        for fb in EVERGREEN_USELESS_FACTS:
            if len(useless_facts) >= 2:
                break
            if not any(f.text == fb.text for f in useless_facts):
                useless_facts.append(fb)

        number_facts: List[FactItem] = []
        for res in results[2:4]:
            if isinstance(res, FactItem):
                number_facts.append(res)
        for fb in EVERGREEN_NUMBER_FACTS:
            if len(number_facts) >= 2:
                break
            if not any(f.text == fb.text for f in number_facts):
                number_facts.append(fb)

        historical_facts: List[FactItem] = []
        hist_res = results[4]
        if isinstance(hist_res, list):
            for item in hist_res:
                if isinstance(item, FactItem):
                    historical_facts.append(item)
        for fb in EVERGREEN_HISTORICAL_FACTS:
            if len(historical_facts) >= 2:
                break
            if not any(f.text == fb.text for f in historical_facts):
                historical_facts.append(fb)

        all_facts = useless_facts[:2] + number_facts[:2] + historical_facts[:2]
        return all_facts

    @classmethod
    async def build_daily_pack(cls, target_date: Optional[date] = None) -> DailyPackSchema:
        """
        Orchestrates parallel fetching of all 15 educational items:
        - 3 Articles
        - 3 Quizzes
        - 3 Cosmos items
        - 6 Facts
        Returns a validated DailyPackSchema payload.
        """
        d = target_date or date.today()
        logger.info("Building DailyPack for date %s...", d)

        articles_res, quizzes_res, cosmos_res, facts_res = await asyncio.gather(
            cls.fetch_articles(d),
            cls.fetch_quizzes(),
            cls.fetch_cosmos(),
            cls.fetch_facts(d),
            return_exceptions=True,
        )

        # Resilient unpack: If an unhandled exception occurred, fallback cleanly
        articles = (
            articles_res
            if isinstance(articles_res, list) and len(articles_res) == 3
            else EVERGREEN_ARTICLES[:3]
        )
        quizzes = (
            quizzes_res
            if isinstance(quizzes_res, list) and len(quizzes_res) == 3
            else EVERGREEN_QUIZZES[:3]
        )
        cosmos = (
            cosmos_res
            if isinstance(cosmos_res, list) and len(cosmos_res) == 3
            else EVERGREEN_COSMOS[:3]
        )
        facts = (
            facts_res
            if isinstance(facts_res, list) and len(facts_res) == 6
            else (EVERGREEN_USELESS_FACTS[:2] + EVERGREEN_NUMBER_FACTS[:2] + EVERGREEN_HISTORICAL_FACTS[:2])
        )

        return DailyPackSchema(
            pack_date=d,
            articles=articles,
            quizzes=quizzes,
            cosmos=cosmos,
            facts=facts,
        )
