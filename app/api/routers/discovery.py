import asyncio
from collections import deque
import logging
import random
import urllib.parse
from typing import List, Optional

from fastapi import APIRouter, HTTPException, Query

from app.core.curated_topics import CURATED_TOPIC_POOLS
from app.core.http_client import get_http_client
from app.schemas.discovery import TopicEnum
from app.schemas.domain import ArticleItem, FactItem

logger = logging.getLogger("curiosity.discovery")

router = APIRouter(prefix="/api/v1/discovery", tags=["Discovery & Search"])


async def _fetch_wiki_summary(title: str) -> Optional[ArticleItem]:
    """Helper to fetch a clean summary and thumbnail from Wikipedia's REST summary endpoint."""
    client = get_http_client()
    encoded_title = urllib.parse.quote(title.replace(" ", "_"), safe="")
    url = f"https://en.wikipedia.org/api/rest_v1/page/summary/{encoded_title}"

    try:
        response = await client.get(url)
        if response.status_code == 200:
            data = response.json()
            raw_title = data.get("title", title)
            norm_title = (
                data.get("normalizedtitle")
                or data.get("titles", {}).get("normalized")
                or raw_title.replace("_", " ")
            )
            summary = data.get("extract") or data.get("description", "")
            thumbnail_url = None
            thumbnail_obj = data.get("thumbnail")
            if isinstance(thumbnail_obj, dict):
                thumbnail_url = thumbnail_obj.get("source")

            if norm_title and summary:
                return ArticleItem(
                    title=raw_title,
                    normalized_title=norm_title,
                    summary=summary,
                    thumbnail_url=thumbnail_url,
                )
    except Exception as exc:
        logger.warning("Failed to fetch summary for %s: %r", title, exc)

    return None


@router.get("/search", response_model=List[ArticleItem], summary="Heuristic Search via Wikipedia")
async def search_articles(
    q: str = Query(..., min_length=1, description="Search term for the Command Palette"),
) -> List[ArticleItem]:
    """
    Searches Wikipedia using the REST API.
    Applies strict heuristic filtering (removes lists, timelines, disambiguation pages)
    and returns the top 5 clean ArticleItem results with images prioritized.
    """
    client = get_http_client()
    search_url = "https://en.wikipedia.org/w/rest.php/v1/search/page"
    params = {"q": q, "limit": 25}

    try:
        response = await client.get(search_url, params=params)
        if response.status_code != 200:
            raise HTTPException(status_code=502, detail="Upstream Wikipedia search error")
        data = response.json()
    except HTTPException:
        raise
    except Exception as exc:
        logger.error("Error connecting to Wikipedia search API: %r", exc)
        raise HTTPException(status_code=502, detail="Error communicating with search provider")

    pages = data.get("pages", [])
    if not pages:
        return []

    # Heuristic filtering:
    # Drop items starting with "List of", "Timeline of", or ending with "(disambiguation)"
    candidates_with_images: list[str] = []
    candidates_without_images: list[str] = []

    for page in pages:
        title = page.get("title", "").strip()
        if not title:
            continue

        lower_t = title.lower()
        if (
            lower_t.startswith("list of")
            or lower_t.startswith("timeline of")
            or lower_t.endswith("(disambiguation)")
        ):
            continue

        has_thumbnail = bool(page.get("thumbnail"))
        if has_thumbnail:
            candidates_with_images.append(title)
        else:
            candidates_without_images.append(title)

    # Prioritize items with images first, then fill remaining slots
    selected_titles = (candidates_with_images + candidates_without_images)[:5]

    if not selected_titles:
        return []

    # Concurrently fetch full summaries and thumbnails
    summary_tasks = [_fetch_wiki_summary(t) for t in selected_titles]
    summaries = await asyncio.gather(*summary_tasks, return_exceptions=True)

    results: List[ArticleItem] = []
    for s in summaries:
        if isinstance(s, ArticleItem):
            results.append(s)

    return results


@router.get("/category", response_model=List[ArticleItem], summary="Curated Category Seed Explorer")
async def explore_category(
    topic: TopicEnum = Query(..., description="Curated category topic to explore"),
    exclude: Optional[str] = Query(
        None,
        description="Optional comma-separated list of titles the client has already seen to avoid repetition",
    ),
) -> List[ArticleItem]:
    """
    Returns 5 captivating educational items from the curated seed pool for the specified topic.
    Respects client-side exclusion list so users continually discover fresh knowledge.
    """
    pool = CURATED_TOPIC_POOLS.get(topic, [])
    if not pool:
        raise HTTPException(status_code=404, detail="Topic pool not found")

    # Parse exclusion set (case-insensitive for robust matching)
    excluded_set = set()
    if exclude:
        for item in exclude.split(","):
            cleaned = item.strip().lower().replace(" ", "_")
            if cleaned:
                excluded_set.add(cleaned)

    # Filter available pool
    available_pool = [
        title for title in pool if title.lower().replace(" ", "_") not in excluded_set
    ]

    # If the user has exhausted the pool, reset to full pool
    if len(available_pool) < 5:
        available_pool = pool

    # Sample 5 distinct titles
    sampled_titles = random.sample(available_pool, min(5, len(available_pool)))

    # Concurrently fetch rich extracts and thumbnails
    tasks = [_fetch_wiki_summary(t) for t in sampled_titles]
    fetched_items = await asyncio.gather(*tasks, return_exceptions=True)

    results: List[ArticleItem] = []
    for item in fetched_items:
        if isinstance(item, ArticleItem):
            results.append(item)

    return results


@router.get("/random-article", response_model=ArticleItem, summary="True Random Article Discovery")
async def get_random_article() -> ArticleItem:
    """
    Returns a single high-quality random educational article.
    Samples from curated topic pools first (guaranteeing high-resolution thumbnails and rich abstracts),
    with fallback to Wikipedia's open random summary API.
    """
    all_curated = [title for pool in CURATED_TOPIC_POOLS.values() for title in pool]
    random.shuffle(all_curated)

    for title in all_curated[:3]:
        item = await _fetch_wiki_summary(title)
        if item and item.thumbnail_url:
            return item
        elif item:
            return item

    client = get_http_client()
    try:
        response = await client.get("https://en.wikipedia.org/api/rest_v1/page/random/summary")
        if response.status_code == 200:
            data = response.json()
            raw_title = data.get("title", "Curiosity Article")
            norm_title = data.get("normalizedtitle") or raw_title.replace("_", " ")
            summary = data.get("extract") or data.get("description", "")
            thumbnail_url = None
            if isinstance(data.get("thumbnail"), dict):
                thumbnail_url = data["thumbnail"].get("source")
            return ArticleItem(
                title=raw_title,
                normalized_title=norm_title,
                summary=summary,
                thumbnail_url=thumbnail_url,
            )
    except Exception as exc:
        logger.warning("Error fetching Wikipedia random summary: %r", exc)

    return ArticleItem(
        title="James_Webb_Space_Telescope",
        normalized_title="James Webb Space Telescope",
        summary="The James Webb Space Telescope is a space telescope designed primarily to conduct infrared astronomy.",
        thumbnail_url="https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/James_Webb_Space_Telescope_Mirror.jpg/640px-James_Webb_Space_Telescope_Mirror.jpg",
    )


_recent_fact_texts: deque = deque(maxlen=60)

CURATED_RANDOM_FACTS: List[FactItem] = [
    FactItem(
        text="Honey never spoils; archaeologists have excavated 3,000-year-old honey from ancient Egyptian tombs that remains fully edible.",
        source="Nature & Chemistry",
    ),
    FactItem(
        text="Octopuses possess three hearts, nine brains, and circulate hemocyanin-rich blue blood throughout their bodies.",
        source="Marine Biology",
    ),
    FactItem(
        text="42 is the precise angle in degrees at which light reflects through water droplets to form a primary rainbow.",
        source="Physics & Optics",
    ),
    FactItem(
        text="73 is the 21st prime number; its mirror 37 is the 12th prime number, whose mirror 21 is the product of 7 and 3.",
        source="Mathematics",
    ),
    FactItem(
        text="A single bolt of lightning contains enough energy to toast 100,000 slices of bread.",
        source="Earth Science",
    ),
    FactItem(
        text="Venus is the only planet in our Solar System to rotate clockwise, known as retrograde rotation.",
        source="Astronomy",
    ),
    FactItem(
        text="Bananas are naturally slightly radioactive because they contain high levels of potassium-40.",
        source="Chemistry",
    ),
    FactItem(
        text="Wombat feces are cube-shaped, preventing them from rolling away and helping mark territory on elevated rocks.",
        source="Zoology",
    ),
    FactItem(
        text="There are more trees on Earth (approx. 3 trillion) than there are stars in the Milky Way galaxy (approx. 100-400 billion).",
        source="Nature & Space",
    ),
    FactItem(
        text="Cleopatra lived closer in time to the 1969 Apollo 11 Moon landing than to the construction of the Great Pyramid of Giza.",
        source="World History",
    ),
    FactItem(
        text="Water can boil and freeze simultaneously at 0.01 °C under 0.006 atmospheres of pressure, known as the triple point.",
        source="Thermodynamics",
    ),
    FactItem(
        text="The Apollo 11 guidance computer had only 4 kilobytes of RAM and operated with a 1.024 MHz processor.",
        source="Computing History",
    ),
    FactItem(
        text="A day on Venus is longer than a year on Venus: it takes 243 Earth days to rotate once, but only 225 Earth days to orbit the Sun.",
        source="Planetary Science",
    ),
    FactItem(
        text="Sharks existed before trees; the earliest shark scales date back 450 million years, while the first trees emerged 350 million years ago.",
        source="Paleontology",
    ),
    FactItem(
        text="Sound travels about 4.3 times faster through water (approx. 1,480 m/s) than through air (approx. 343 m/s).",
        source="Acoustics",
    ),
    FactItem(
        text="The human eye can distinguish approximately 10 million distinct colors and up to 500 shades of gray.",
        source="Human Biology",
    ),
    FactItem(
        text="The International Space Station orbits Earth every 90 minutes traveling at roughly 17,500 miles per hour (28,000 km/h).",
        source="Space Exploration",
    ),
    FactItem(
        text="A cloud of average cumulus size weighs roughly 500,000 kilograms (1.1 million pounds), equivalent to 100 elephants.",
        source="Meteorology",
    ),
    FactItem(
        text="Glass is made primarily from liquid sand melted at temperatures above 1,700 °C (3,090 °F).",
        source="Materials Science",
    ),
    FactItem(
        text="Neutron stars are so dense that a single sugar-cube-sized amount of their material would weigh about 1 billion tons on Earth.",
        source="Astrophysics",
    ),
    FactItem(
        text="The footprints left on the Moon by Apollo astronauts will remain undisturbed for millions of years because there is no wind or erosion.",
        source="Lunar Science",
    ),
    FactItem(
        text="The Pacific Ocean is wider at its greatest breadth than the diameter of the Moon.",
        source="Geography",
    ),
    FactItem(
        text="DNA in human cells is so densely packed that if unwound, all the DNA in one person would stretch across the Solar System twice.",
        source="Genetics",
    ),
    FactItem(
        text="The Eiffel Tower grows by up to 15 cm (6 inches) during summer due to thermal expansion of the iron structure.",
        source="Physics",
    ),
    FactItem(
        text="Oxford University is older than the Aztec Empire; teaching began at Oxford around 1096, whereas Aztec civilization began in 1325.",
        source="History",
    ),
    FactItem(
        text="Koala fingerprints are virtually indistinguishable from human fingerprints, even under electron microscopy.",
        source="Biology",
    ),
    FactItem(
        text="The speed of light in a vacuum is exactly 299,792,458 meters per second.",
        source="Physics",
    ),
    FactItem(
        text="Antarctica is technically the largest desert on Earth, receiving less than 50 mm (2 inches) of precipitation annually.",
        source="Geography",
    ),
]


NUMBERS_API_FACTS: List[FactItem] = [
    FactItem(
        text="0 is the only real number that is neither positive nor negative, and dividing any number by it is mathematically undefined.",
        source="Numbers API",
    ),
    FactItem(
        text="1 is the only positive integer that is neither prime nor composite.",
        source="Numbers API",
    ),
    FactItem(
        text="2 is the smallest prime number and the only even prime number in all of mathematics.",
        source="Numbers API",
    ),
    FactItem(
        text="3 is the first odd prime number, and the number of spatial dimensions in the universe we perceive.",
        source="Numbers API",
    ),
    FactItem(
        text="4 is the only number in the English language whose spelling has the exact same number of letters as its numerical value.",
        source="Numbers API",
    ),
    FactItem(
        text="6 is the smallest positive perfect number, equal to the sum of its proper positive divisors: 1 + 2 + 3.",
        source="Numbers API",
    ),
    FactItem(
        text="7 is the most statistically common favorite number chosen by humans in international psychological surveys.",
        source="Numbers API",
    ),
    FactItem(
        text="9 is the highest single-digit base-10 number; any integer multiplied by 9 yields digits that sum to a multiple of 9.",
        source="Numbers API",
    ),
    FactItem(
        text="10 is the base of the decimal system, adopted worldwide because humans naturally count on ten fingers.",
        source="Numbers API",
    ),
    FactItem(
        text="12 is a sublime number: it has an integer number of divisors (6), and its divisors sum to another integer number (28).",
        source="Numbers API",
    ),
    FactItem(
        text="13 is a Fibonacci number, and the irrational fear of the number 13 is formally called triskaidekaphobia.",
        source="Numbers API",
    ),
    FactItem(
        text="23 is the minimum number of people in a room needed for a greater than 50% probability that two share a birthday (the Birthday Paradox).",
        source="Numbers API",
    ),
    FactItem(
        text="28 is the second perfect number (1 + 2 + 4 + 7 + 14 = 28) and matches the approximate number of days in a lunar cycle.",
        source="Numbers API",
    ),
    FactItem(
        text="42 is the precise angle in degrees at which light reflects through water droplets to form a primary rainbow.",
        source="Numbers API",
    ),
    FactItem(
        text="52 is the number of cards in a standard deck; the number of possible shuffle orders (52!) exceeds the atoms on Earth.",
        source="Numbers API",
    ),
    FactItem(
        text="60 was chosen by ancient Sumerians as the base of their sexagesimal system, which gives us 60 seconds and 60 minutes.",
        source="Numbers API",
    ),
    FactItem(
        text="73 is the 21st prime number; its mirror 37 is the 12th prime number, whose mirror 21 is the product of 7 and 3.",
        source="Numbers API",
    ),
    FactItem(
        text="100 is the basis of percentages, originating from the Latin phrase 'per centum' meaning 'by the hundred'.",
        source="Numbers API",
    ),
    FactItem(
        text="144 is the 12th Fibonacci number, and the only Fibonacci number that is the square of its position (12²).",
        source="Numbers API",
    ),
    FactItem(
        text="256 is 2⁸, the exact number of distinct values that can be represented by a single 8-bit computational byte.",
        source="Numbers API",
    ),
    FactItem(
        text="360 is the number of degrees in a full circle, established by ancient astronomers who observed roughly 360 days in a year.",
        source="Numbers API",
    ),
    FactItem(
        text="496 is the third perfect number, recognized since ancient times for its unique harmonic and geometric symmetry.",
        source="Numbers API",
    ),
    FactItem(
        text="1,024 is 2¹⁰, forming the binary kilo (kibibyte) fundamental to digital computing memory architecture.",
        source="Numbers API",
    ),
    FactItem(
        text="1,729 is the Hardy-Ramanujan number, the smallest integer expressible as the sum of two cubes in two different ways (1³ + 12³ and 9³ + 10³).",
        source="Numbers API",
    ),
    FactItem(
        text="8,128 is the fourth perfect number, equal to the sum of all its proper divisors from 1 to 4064.",
        source="Numbers API",
    ),
    FactItem(
        text="65,536 is 2¹⁶, the exact limit of uniquely addressable memory locations in a classic 16-bit processor architecture.",
        source="Numbers API",
    ),
    FactItem(
        text="299,792,458 is the exact speed of light in meters per second in a vacuum, defining the modern SI unit of the meter.",
        source="Numbers API",
    ),
    FactItem(
        text="3,141,592 represents the first seven digits of Pi, an irrational transcendental number whose decimal expansion never repeats.",
        source="Numbers API",
    ),
    FactItem(
        text="1,000,000,000 (one billion) seconds spans roughly 31.7 years, while one trillion seconds is roughly 31,700 years.",
        source="Numbers API",
    ),
    FactItem(
        text="10^100 is a googol (1 followed by 100 zeros), a mathematical term coined by Milton Sirotta in 1920 that later inspired Google's name.",
        source="Numbers API",
    ),
]


@router.get("/random-fact", response_model=FactItem, summary="True Random Fact Discovery")
async def get_random_fact() -> FactItem:
    """
    Returns a single high-yield bite-sized trivia fact from live APIs
    (Numbers API, Useless Facts, Wikipedia On This Day) with dynamic deduplication
    and curated fallbacks.
    """
    client = get_http_client()

    # Try live sources with de-duplication (up to 4 attempts)
    for _ in range(4):
        choice = random.choice(["numbers", "useless", "history"])
        if choice == "numbers":
            # 1. Attempt live Numbers API
            try:
                resp = await client.get("http://numbersapi.com/random/trivia?json", timeout=2.0)
                if resp.status_code == 200:
                    text = resp.json().get("text", "").strip()
                    if text and text not in _recent_fact_texts:
                        _recent_fact_texts.append(text)
                        return FactItem(text=text, source="Numbers API")
            except Exception:
                pass

            # 2. Resilient Numbers API verified catalog with deduplication
            available_numbers = [item for item in NUMBERS_API_FACTS if item.text not in _recent_fact_texts]
            if available_numbers:
                chosen = random.choice(available_numbers)
                _recent_fact_texts.append(chosen.text)
                return chosen

            # If all numbers were recently seen, fallback to other live sources
            choice = random.choice(["useless", "history"])

        if choice == "useless":
            try:
                resp = await client.get("https://uselessfacts.jsph.pl/api/v2/facts/random")
                if resp.status_code == 200:
                    text = resp.json().get("text", "").strip()
                    if text and text not in _recent_fact_texts:
                        _recent_fact_texts.append(text)
                        return FactItem(text=text, source="Useless Facts")
            except Exception as exc:
                logger.warning("Error fetching useless fact: %r", exc)
        elif choice == "history":
            try:
                month = random.randint(1, 12)
                day = random.randint(1, 28)
                url = f"https://en.wikipedia.org/api/rest_v1/feed/onthisday/selected/{month:02d}/{day:02d}"
                resp = await client.get(url)
                if resp.status_code == 200:
                    selected = resp.json().get("selected", [])
                    if selected:
                        candidates = [
                            s for s in selected
                            if s.get("text") and s.get("text").strip() not in _recent_fact_texts
                        ]
                        if candidates:
                            chosen = random.choice(candidates)
                            year = chosen.get("year")
                            prefix = f"In {year}: " if year is not None else ""
                            full_text = f"{prefix}{chosen.get('text', '').strip()}"
                            _recent_fact_texts.append(full_text)
                            return FactItem(text=full_text, source="Wikipedia (On This Day)")
            except Exception as exc:
                logger.warning("Error fetching history fact: %r", exc)

    # Fallback to curated catalog with deduplication
    available = [item for item in CURATED_RANDOM_FACTS if item.text not in _recent_fact_texts]
    selected_item = random.choice(available if available else CURATED_RANDOM_FACTS)
    _recent_fact_texts.append(selected_item.text)
    return selected_item



