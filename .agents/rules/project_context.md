# Project Context & Architecture Decisions

This file tracks the core architectural and design decisions for the "Curiosity" style microlearning app to ensure context is maintained across sessions.

## 1. Daily Payload Strategy (14 Items/Day)
- **Content Mix**: 3 Articles, 3 Quizzes, 3 Cosmos, 5 Facts.
- **Fixed Daily Quota**: Hard-capped at 14 items to prevent doomscrolling and provide a satisfying "Inbox Zero" completion feeling.
- **Handling API Limitations**: Since NASA APOD and Wikimedia typically provide 1 featured item per day, the backend will fulfill the quota of 3 by fetching 1 current item + 2 historical/random items.

## 2. Article Summarization (Microlearning UX)
- **TL;DR First**: To prevent cognitive overload, the app will not display 3 full long-form articles in the main feed.
- **Wikipedia Summary API**: The backend will use `https://en.wikipedia.org/api/rest_v1/page/summary/{title}` to fetch the `extract` (intro paragraph) and `thumbnail`. 
- **Deep Dive WebView**: The Flutter UI will display the extract and thumbnail in the main feed card. A "Read Full Article" button will open the `content_urls.mobile.page` in an edge-to-edge in-app WebView.

## 3. Storage & Frictionless UX
- **No Forced Logins**: The app prioritizes a frictionless, immediate-start experience.
- **Local Storage ("The Vault")**: Bookmarks, read statuses, and the daily badge decrementing state are stored entirely locally on the device (using SQLite/Hive) to support offline-first usage.

## 4. Backend Scalability
- **Midnight Aggregation**: Handled via `APScheduler` in the FastAPI backend. 
- **Future Scalability Note**: When scaling to multiple server workers in production, the scheduler must be updated to use a distributed lock (e.g., Redis) or an async task queue (e.g., Arq) to prevent duplicate API calls at midnight.

## 5. Anti-Slop UI Architecture (Geist / Vercel Aesthetic)
- **No Default Material**: We will explicitly strip out Flutter's default "Material 3" look (no default blue app bars, no pill-shaped generic buttons, no heavy drop shadows).
- **Light & Dark Mode**: The app will fully support both system themes using the strict Geist aesthetic:
  - **Dark Mode**: Pure black (`#000000`) background, stark white text, and subtle white hairline borders (`rgba(255,255,255,0.1)`).
  - **Light Mode**: Pure white (`#FFFFFF`) background, pure black text, and subtle gray hairline borders (`rgba(0,0,0,0.1)`).
- **Custom ThemeData**: The Flutter app will utilize a strict `ThemeData` file at the root for BOTH light and dark modes to force the agent to use only the pre-approved design tokens, completely preventing the generation of generic, inline "AI slop" styles.
- **Typography First**: We will use a premium geometric sans-serif font (like Inter or Geist) with tight tracking and high contrast.

## 6. Pre-Review & Approval Policy
- **Never Modify Without Prior Review**: Do NOT make code, configuration, or file changes on your own before reviewing them with the user first.
- **Always Plan and Propose**: First investigate, clearly explain the findings and proposed solution, and wait for explicit user confirmation before touching or modifying any files.
- **Respect User Oversight**: The user must always remain in the loop and approve changes prior to execution.

## 7. Cloud Infrastructure Invariants (Neon, Upstash, & CORS)
- **Neon PostgreSQL & asyncpg**:
  - Automatically normalize schemes (`postgresql://` -> `postgresql+asyncpg://`).
  - Strip libpq parameters (`sslmode`, `channel_binding`, `target_session_attrs`) from URLs and pass `connect_args={"ssl": True}`.
  - Detect `-pooler` hostnames and inject `statement_cache_size=0` to prevent PgBouncer prepared statement collisions.
  - Ensure `Base.metadata.create_all` executes on primary database connection for automatic table provisioning.
- **Upstash Redis**:
  - Always enforce `rediss://` (TLS) for Upstash endpoints.
  - Configure `socket_connect_timeout=5.0`, `retry_on_timeout=True`, and `health_check_interval=30` to protect against serverless socket drops.
- **Upstash QStash & Cron**:
  - Enforce `CRON_SECRET` verification using `hmac.compare_digest`.
  - Use `Upstash-Forward-<Header>` for forwarding custom headers to destination endpoints.
  - Support regional QStash endpoints (e.g. `https://qstash-us-east-1.upstash.io`).
- **CORS & Multiplatform Images**:
  - Never pair `allow_origins=["*"]` with `allow_credentials=True`.
  - Never hardcode `http://localhost:8000` in backend JSON payloads; return canonical URLs and let Flutter's `ImageUtils` resolve platform-specific proxying dynamically.

