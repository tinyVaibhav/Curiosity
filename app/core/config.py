from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    # Database Settings
    # Production / Staging: PostgreSQL via asyncpg
    # Local Dev: SQLite fallback via aiosqlite when PostgreSQL is not running
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/curiosity_db"
    FALLBACK_DATABASE_URL: str = "sqlite+aiosqlite:///./curiosity_dev.db"
    AUTO_FALLBACK_DATABASE: bool = True

    # Cache Settings
    REDIS_URL: str = "redis://localhost:6379/0"
    CACHE_TTL_SECONDS: int = 86400  # 24 hours
    AUTO_FALLBACK_CACHE: bool = True  # Fallback to in-memory TTL cache if Redis unavailable

    # External API Settings
    NASA_API_KEY: str = "DEMO_KEY"
    HTTP_TIMEOUT_SECONDS: float = 10.0

    # Cron & Automation Settings (Upstash QStash / Internal Scheduler)
    CRON_SECRET: str = "curiosity_dev_cron_secret_change_in_production"
    ENABLE_INTERNAL_SCHEDULER: bool = True
    QSTASH_TOKEN: str | None = None
    QSTASH_URL: str = "https://qstash.upstash.io"
    PUBLIC_BASE_URL: str | None = None  # e.g. "https://my-curiosity-api.onrender.com"
    QSTASH_CURRENT_SIGNING_KEY: str | None = None
    QSTASH_NEXT_SIGNING_KEY: str | None = None

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

settings = Settings()
