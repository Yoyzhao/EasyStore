import copy
import json
import os
import shutil
from typing import Dict, Any
from app.core.config import settings

SETTINGS_FILE = settings.SETTINGS_FILE

def get_abs_path(path: str) -> str:
    """计算绝对路径，不改变全局 settings 对象状态"""
    if os.path.isabs(path):
        resolved_path = path
    else:
        resolved_path = os.path.join(settings.APP_HOME, path)
    return os.path.abspath(os.path.normpath(resolved_path))

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
        res = copy.deepcopy(DEFAULT_SETTINGS)
        res["storage"]["current_abs_path"] = settings.DATA_PATH
        return res
    
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
            merged["storage"]["current_abs_path"] = settings.DATA_PATH
            return merged
    except Exception:
        settings.ensure_runtime_directories()
        DEFAULT_SETTINGS["storage"]["current_abs_path"] = settings.DATA_PATH
        return DEFAULT_SETTINGS

def update_settings(new_settings: Dict[str, Any]) -> Dict[str, Any]:
    current_settings = get_settings()
    
    # 记录旧路径和新路径
    old_data_path = current_settings.get("storage", {}).get("data_path", "data")
    new_data_path = new_settings.get("storage", {}).get("data_path", old_data_path)
    migration_action = new_settings.get("storage", {}).get("migration_action", "none")
    
    # 如果路径发生了变化且选择了迁移或新建
    if old_data_path != new_data_path:
        old_abs_path = get_abs_path(old_data_path)
        new_abs_path = get_abs_path(new_data_path)
        
        if migration_action == "migrate":
            # 迁移数据：复制旧目录内容到新目录
            if os.path.exists(old_abs_path) and old_abs_path != new_abs_path:
                os.makedirs(new_abs_path, exist_ok=True)
                for item in os.listdir(old_abs_path):
                    s = os.path.join(old_abs_path, item)
                    d = os.path.join(new_abs_path, item)
                    try:
                        if os.path.isdir(s):
                            if os.path.exists(d):
                                shutil.copytree(s, d, dirs_exist_ok=True)
                            else:
                                shutil.copytree(s, d)
                        else:
                            shutil.copy2(s, d)
                    except Exception as e:
                        print(f"Migration error for {item}: {e}")
        elif migration_action == "create_new":
            # 新建目录：只需确保新目录存在即可
            os.makedirs(new_abs_path, exist_ok=True)

    # 更新设置
    if "upload" in new_settings:
        current_settings["upload"].update(new_settings["upload"])
    if "access" in new_settings:
        current_settings["access"].update(new_settings["access"])
    if "storage" in new_settings:
        current_settings["storage"].update(new_settings["storage"])
    if "general" in new_settings:
        current_settings["general"].update(new_settings["general"])
        
    os.makedirs(os.path.dirname(SETTINGS_FILE), exist_ok=True)
    # 移除临时字段，不保存到 settings.json
    save_data = copy.deepcopy(current_settings)
    if "storage" in save_data:
        if "current_abs_path" in save_data["storage"]:
            del save_data["storage"]["current_abs_path"]
        if "migration_action" in save_data["storage"]:
            del save_data["storage"]["migration_action"]
        
    with open(SETTINGS_FILE, "w", encoding="utf-8") as f:
        json.dump(save_data, f, indent=4)
    
    # 强制重新加载 settings.json 相关的动态属性（可选，取决于 settings 类实现）
    # 在本例中，settings.DATA_PATH 是动态属性，直接访问即可反映最新状态
    settings.ensure_runtime_directories()
    
    current_settings["storage"]["current_abs_path"] = settings.DATA_PATH
    return current_settings
