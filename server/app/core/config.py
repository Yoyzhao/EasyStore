import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "EasyStore"
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str = "supersecretkey_easy_store_2024_00001" # In production, this should be an environment variable
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7 # 7 days
    
    # SQLite configuration
    BASE_DIR: str = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../"))
    DATABASE_URL: str = f"sqlite:///{os.path.join(BASE_DIR, 'data/db/easystore.db')}"
    UPLOAD_DIR: str = os.path.join(BASE_DIR, "data/uploads")

settings = Settings()
