"""应用配置 — 通过环境变量覆盖，开发环境直接用默认值"""

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # ── 应用 ──
    APP_NAME: str = "TestPilot"
    APP_VERSION: str = "0.1.0"
    DEBUG: bool = True

    # ── 数据库 (本地 MySQL) ──
    DB_HOST: str = "127.0.0.1"
    DB_PORT: int = 3306
    DB_USER: str = "root"
    DB_PASSWORD: str = "root"
    DB_NAME: str = "testpilot"
    DATABASE_URL: str = ""

    @property
    def db_url(self) -> str:
        if self.DATABASE_URL:
            return self.DATABASE_URL
        return (
            f"mysql+pymysql://{self.DB_USER}:{self.DB_PASSWORD}"
            f"@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"
            "?charset=utf8mb4"
        )

    # ── JWT ──
    SECRET_KEY: str = "testpilot-dev-secret-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 24小时

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


settings = Settings()
