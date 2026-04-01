import os
import json
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "EasyStore"
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str = "supersecretkey_easy_store_2024_00001" # In production, this should be an environment variable
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7 # 7 days
    
    # Base directory
    BASE_DIR: str = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../"))
    
    # Load dynamic settings from data/settings.json if exists
    def _get_dynamic_setting(self, section, key, default):
        settings_path = os.path.join(self.BASE_DIR, "data", "settings.json")
        if os.path.exists(settings_path):
            try:
                with open(settings_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    return data.get(section, {}).get(key, default)
            except:
                pass
        return default

    @property
    def DATA_PATH(self) -> str:
        path = self._get_dynamic_setting("storage", "data_path", "data")
        if os.path.isabs(path):
            return path
        return os.path.join(self.BASE_DIR, path)

    @property
    def DATABASE_URL(self) -> str:
        db_path = os.path.join(self.DATA_PATH, "db", "easystore.db")
        os.makedirs(os.path.dirname(db_path), exist_ok=True)
        return f"sqlite:///{db_path}"

    @property
    def UPLOAD_DIR(self) -> str:
        upload_path = os.path.join(self.DATA_PATH, "uploads")
        os.makedirs(upload_path, exist_ok=True)
        return upload_path
    
    @property
    def APP_PROJECT_NAME(self) -> str:
        return self._get_dynamic_setting("general", "project_name", self.PROJECT_NAME)
    
    @property
    def APP_PORT(self) -> int:
        return self._get_dynamic_setting("general", "port", 8000)

settings = Settings()
