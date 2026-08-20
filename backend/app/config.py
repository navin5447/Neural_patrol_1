from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "SpeciesTrace"
    environment: str = "development"
    database_url: str = "sqlite:///./speciestrace.db"
    secret_key: str = "dev-secret-key-change-me"
    allowed_origins: str = "*"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24

    model_config = SettingsConfigDict(env_file=".env", case_sensitive=False)


settings = Settings()
