import json
import os
from typing import Dict, Any
from app.core.config import settings

SETTINGS_FILE = os.path.join(settings.BASE_DIR, "data", "settings.json")

DEFAULT_SETTINGS = {
    "upload": {
        "max_size_mb": 5,
        "allowed_extensions": ["jpg", "jpeg", "png", "gif", "webp"]
    },
    "access": {
        "allow_external_ip": False
    }
}

def get_settings() -> Dict[str, Any]:
    if not os.path.exists(SETTINGS_FILE):
        os.makedirs(os.path.dirname(SETTINGS_FILE), exist_ok=True)
        with open(SETTINGS_FILE, "w", encoding="utf-8") as f:
            json.dump(DEFAULT_SETTINGS, f, indent=4)
        return DEFAULT_SETTINGS
    
    try:
        with open(SETTINGS_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
            # Merge with default settings to ensure all keys exist
            merged = DEFAULT_SETTINGS.copy()
            if "upload" in data:
                merged["upload"].update(data["upload"])
            if "access" in data:
                merged["access"].update(data["access"])
            return merged
    except Exception:
        return DEFAULT_SETTINGS

def update_settings(new_settings: Dict[str, Any]) -> Dict[str, Any]:
    current_settings = get_settings()
    if "upload" in new_settings:
        current_settings["upload"].update(new_settings["upload"])
    if "access" in new_settings:
        current_settings["access"].update(new_settings["access"])
        
    os.makedirs(os.path.dirname(SETTINGS_FILE), exist_ok=True)
    with open(SETTINGS_FILE, "w", encoding="utf-8") as f:
        json.dump(current_settings, f, indent=4)
        
    return current_settings
