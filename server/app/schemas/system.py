from typing import List
from pydantic import BaseModel

class UploadSettings(BaseModel):
    max_size_mb: int
    allowed_extensions: List[str]

class SystemSettings(BaseModel):
    upload: UploadSettings
