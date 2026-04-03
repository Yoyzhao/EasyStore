import json
import os
from typing import Any

from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "EasyStore"
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str = "supersecretkey_easy_store_2024_00001"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7
    
    # 显式定义 .env 中可能存在的变量
    EASYSTORE_PORT: int = 8000
    EASYSTORE_DATA_PATH: str = "data"
    EASYSTORE_APP_HOME: str = "."
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True
        extra = "ignore" # 忽略未定义的额外变量，防止报错
    
    # Base directory
    @property
    def BASE_DIR(self) -> str:
        import sys
        if getattr(sys, 'frozen', False):
            return os.path.dirname(sys.executable)
        return os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../"))

    @property
    def APP_HOME(self) -> str:
        if self.EASYSTORE_APP_HOME:
            os.makedirs(self.EASYSTORE_APP_HOME, exist_ok=True)
            return self.EASYSTORE_APP_HOME
        return self.BASE_DIR

    @property
    def SETTINGS_FILE(self) -> str:
        settings_file = os.path.join(self.APP_HOME, "data", "settings.json")
        os.makedirs(os.path.dirname(settings_file), exist_ok=True)
        return settings_file

    def _read_dynamic_settings(self) -> dict[str, Any]:
        if os.path.exists(self.SETTINGS_FILE):
            try:
                with open(self.SETTINGS_FILE, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception:
                return {}
        return {}

    def _get_dynamic_setting(self, section: str, key: str, default: Any):
        data = self._read_dynamic_settings()
        if isinstance(data, dict):
            return data.get(section, {}).get(key, default)
        return default

    @property
    def DATA_PATH(self) -> str:
        path = self.EASYSTORE_DATA_PATH or self._get_dynamic_setting("storage", "data_path", "data")
        if os.path.isabs(path):
            resolved_path = path
        else:
            resolved_path = os.path.join(self.APP_HOME, path)
        os.makedirs(resolved_path, exist_ok=True)
        return resolved_path

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

    def ensure_runtime_directories(self) -> None:
        os.makedirs(self.DATA_PATH, exist_ok=True)
        os.makedirs(os.path.join(self.DATA_PATH, "db"), exist_ok=True)
        os.makedirs(self.UPLOAD_DIR, exist_ok=True)
        os.makedirs(os.path.dirname(self.SETTINGS_FILE), exist_ok=True)
    
    @property
    def APP_PROJECT_NAME(self) -> str:
        return self._get_dynamic_setting("general", "project_name", self.PROJECT_NAME)
    
    @property
    def APP_PORT(self) -> int:
        if self.EASYSTORE_PORT:
            return self.EASYSTORE_PORT
        return self._get_dynamic_setting("general", "port", 8000)

settings = Settings()
