# Project TODOs

## Backend Architecture
- [ ] **Midnight Data Aggregation**: Currently implemented as a simple local run for testing purposes. Before production deployment, update the APScheduler implementation to handle concurrency (e.g., using a Redis distributed lock or migrating to a task queue like Arq/Celery) to prevent duplicate aggregation runs when scaling to multiple workers.
- [ ] **Cloud Sync & User State**: For the testing phase, the backend is completely stateless (serving only the `DailyPack` payload). Before production or in a future phase, introduce `User`, `Bookmark`, and `UserView` tables to allow the mobile app to sync its local SQLite data to the cloud for cross-device backup.
- [ ] **Production Infrastructure Integration Testing**: For local testing, an in-memory cache and SQLite fallback are used when Redis/PostgreSQL are not present. Before making changes live, verify connection pooling, real Redis cache eviction, and PostgreSQL JSONB queries in a staging environment with live Redis and Postgres instances.
