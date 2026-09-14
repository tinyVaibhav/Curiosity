# Changelog

All notable changes to the Curiosity project are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] - 2026-09-14

### Added
- **Nordic Clay & Sage Design System**:
  - Implemented Scandinavian warmth palette featuring Cream `#F5F0EB`, Sand Clay `#EDE8E1`, Deep Slate `#191C1F`, and Forest Sage `#4D6A56` accents.
  - Added full dynamic ThemeMode switching (System, Light, Dark) with high-contrast text ratios adhering to WCAG 2.1 AA (>4.5:1).
  - Generous 12–16dp radiuses, tactile cards, and elimination of generic default Material styling.
- **In-App Settings Modal & State Management**:
  - Created [`SettingsModal`](mobile/lib/widgets/settings_modal.dart) and [`SettingsProvider`](mobile/lib/core/state/settings_provider.dart).
  - Added controls for Theme Selection (Light / Dark / System), Haptic Feedback toggle, Auto-play Media toggle, and Cache Clearing.
  - Ensured all interactive controls strictly meet the 48×48 dp minimum touch target guideline.
- **Zero-Crop Article Gallery Matting**:
  - Redesigned [`ArticleCard`](mobile/lib/widgets/article_card.dart) thumbnail presentation using `BoxFit.contain` surrounded by an ambient background glow derived from `ImageFilter.blur()`.
  - Upgraded Wikimedia thumbnails dynamically to 640px retina resolution via `ImageUtils.upgradeWikiThumbnail`.
- **Neon Serverless PostgreSQL Integration**:
  - Added automated database URL normalization in [`app/core/database.py`](app/core/database.py):
    - Scheme translation from `postgresql://` or `postgres://` to `postgresql+asyncpg://`.
    - Automatic extraction of `?sslmode=require` into `connect_args['ssl'] = True`.
    - Automatic stripping of unsupported libpq parameters (`channel_binding`, `target_session_attrs`, `gssencmode`).
    - Detection of Neon PgBouncer transaction poolers (`-pooler`) with automatic `statement_cache_size = 0`.
    - Automated schema provisioning (`Base.metadata.create_all`) upon primary database connection.
- **Upstash Serverless Redis Integration**:
  - Added automated URL normalization in [`app/core/cache.py`](app/core/cache.py) upgrading `redis://` to `rediss://` (TLS required over port 6379).
  - Configured cloud serverless connection resilience: `socket_connect_timeout=5.0`, `socket_timeout=5.0`, `retry_on_timeout=True`, and `health_check_interval=30`.
- **Upstash QStash Serverless Cron & Programmatic Management**:
  - Added authenticated cron webhook endpoint `POST /api/v1/cron/daily-pack` in [`app/api/routers/cron.py`](app/api/routers/cron.py).
  - Built programmatic schedule management endpoints:
    - `POST /api/v1/cron/setup-schedule`: One-click QStash schedule registration with automated `Upstash-Forward-Authorization: Bearer <CRON_SECRET>` headers.
    - `GET /api/v1/cron/schedules`: Inspect active schedules and execution timelines.
    - `DELETE /api/v1/cron/schedules/{schedule_id}`: Remove active schedules.
  - Added regional QStash endpoint support (e.g. `https://qstash-us-east-1.upstash.io`).
- **Live Health Diagnostics**:
  - Added `GET /health` endpoint in [`app/main.py`](app/main.py) reporting real-time database and cache connection providers.
- **Configuration & Security**:
  - Added comprehensive [`.env.example`](.env.example) template documenting database, cache, and cron settings while ensuring `.env` remains strictly gitignored.

### Changed
- **W3C CORS Specification Compliance**:
  - Configured `CORSMiddleware` in [`app/main.py`](app/main.py) with `allow_credentials=False` to strictly satisfy browser specifications for wildcard origins (`allow_origins=["*"]`).
- **Eliminated Hardcoded Hostnames**:
  - Removed hardcoded `http://localhost:8000` URLs from [`app/api/routers/feed.py`](app/api/routers/feed.py) and [`app/api/routers/vault.py`](app/api/routers/vault.py), preserving canonical URLs and allowing clients to resolve proxy addresses dynamically.
- **Platform-Aware Image Resolution**:
  - Updated `ImageUtils.baseUrl` in [`mobile/lib/core/utils/image_utils.dart`](mobile/lib/core/utils/image_utils.dart) to dynamically resolve Web hosts from `Uri.base` and re-anchor cached proxy paths across Web, Android emulator (`10.0.2.2`), and physical devices.

### Fixed
- Fixed blank image rendering issue in Flutter Web caused by cold-start race conditions and CanvasKit CORS image texture blocking.
- Fixed `asyncpg` crash when connecting to Neon DB with `&channel_binding=require`.
- Fixed potential PgBouncer prepared statement collisions on Neon connection pooler endpoints.
- Fixed accessibility and touch target sizing across all top bar icons, bottom navigation tabs, and reader modals.

### Verified
- Automated test suites: 16/16 Flutter widget and unit tests passing.
- Backend ASGI diagnostic tests: 4/4 cron authentication tests passing.
- Live database verification: Confirmed direct connection to remote Neon PostgreSQL (`using_fallback: False`) and Upstash Redis.

---

## [1.0.0] - Baseline Release
- Initial baseline architecture: FastAPI backend with SQLite/PostgreSQL support, Wikipedia TFA, NASA APOD, Open Trivia, and Useless Facts aggregation.
- Initial Flutter mobile shell with The Vault and Feed screens.
