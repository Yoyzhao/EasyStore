from typing import List
from pydantic import BaseModel

class UploadSettings(BaseModel):
    max_size_mb: int
    allowed_extensions: List[str]

class AccessSettings(BaseModel):
    allow_external_ip: bool = False

class StorageSettings(BaseModel):
    data_path: str = "data"
    current_abs_path: str = ""
    migration_action: str = "none" # none, migrate, create_new

class GeneralSettings(BaseModel):
    project_name: str = "EasyStore"
    port: int = 8000

class SystemSettings(BaseModel):
    upload: UploadSettings
    access: AccessSettings = AccessSettings()
    storage: StorageSettings = StorageSettings()
    general: GeneralSettings = GeneralSettings()
