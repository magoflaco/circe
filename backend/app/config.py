from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict
class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", extra="ignore"
    )
    app_name: str = "Circe"
    environment: str = "development"
    cors_origins: str = "http://localhost:8080"
    public_base_url: str = "https://api-monitor.itb.lat"
    database_url: str = "sqlite+aiosqlite:///./monitor_biomedico.db"
    jwt_secret: str = "dev-insecure-secret-change-me"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 43200
    groq_api_key: str = ""
    groq_model: str = "llama-3.3-70b-versatile"
    groq_base_url: str = "https://api.groq.com/openai/v1"
    resend_api_key: str = ""
    resend_from: str = "Monitor Biomédico <onboarding@resend.dev>"
    frontend_url: str = "http://localhost:8080"
    @property
    def cors_origins_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]
    @property
    def is_production(self) -> bool:
        return self.environment.lower() == "production"
@lru_cache
def get_settings() -> Settings:
    return Settings()
settings = get_settings()