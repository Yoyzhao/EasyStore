from typing import List
from pydantic import BaseModel

class UploadSettings(BaseModel):
    max_size_mb: int
    allowed_extensions: List[str]

class AccessSettings(BaseModel):
    allow_external_ip: bool = False

class SystemSettings(BaseModel):
    upload: UploadSettings
    access: AccessSettings = AccessSettings()
