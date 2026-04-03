import copy
import json
import os
from typing import Dict, Any
from app.core.config import settings

SETTINGS_FILE = settings.SETTINGS_FILE

DEFAULT_SETTINGS = {
    "upload": {
        "max_size_mb": 5,
        "allowed_extensions": ["jpg", "jpeg", "png", "gif", "webp"]
    },
    "access": {
        "allow_external_ip": False
    },
    "storage": {
        "data_path": "data"
    },
    "general": {
        "project_name": "EasyStore",
        "port": 8000
    }
}

def get_settings() -> Dict[str, Any]:
    if not os.path.exists(SETTINGS_FILE):
        os.makedirs(os.path.dirname(SETTINGS_FILE), exist_ok=True)
        with open(SETTINGS_FILE, "w", encoding="utf-8") as f:
            json.dump(DEFAULT_SETTINGS, f, indent=4)
        settings.ensure_runtime_directories()
        return DEFAULT_SETTINGS
    
    try:
        with open(SETTINGS_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
            merged = copy.deepcopy(DEFAULT_SETTINGS)
            if "upload" in data:
                merged["upload"].update(data["upload"])
            if "access" in data:
                merged["access"].update(data["access"])
            if "storage" in data:
                merged["storage"].update(data["storage"])
            if "general" in data:
                merged["general"].update(data["general"])
            settings.ensure_runtime_directories()
            return merged
    except Exception:
        settings.ensure_runtime_directories()
        return DEFAULT_SETTINGS

def update_settings(new_settings: Dict[str, Any]) -> Dict[str, Any]:
    current_settings = get_settings()
    if "upload" in new_settings:
        current_settings["upload"].update(new_settings["upload"])
    if "access" in new_settings:
        current_settings["access"].update(new_settings["access"])
    if "storage" in new_settings:
        current_settings["storage"].update(new_settings["storage"])
    if "general" in new_settings:
        current_settings["general"].update(new_settings["general"])
        
    os.makedirs(os.path.dirname(SETTINGS_FILE), exist_ok=True)
    with open(SETTINGS_FILE, "w", encoding="utf-8") as f:
        json.dump(current_settings, f, indent=4)
    settings.ensure_runtime_directories()
        
    return current_settings
