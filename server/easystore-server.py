import uvicorn
import os
import sys
import multiprocessing

# Add the current directory to sys.path to ensure 'app' can be found
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.config import settings

if __name__ == "__main__":
    # For PyInstaller on Windows
    multiprocessing.freeze_support()
    
    print(f"Starting EasyStore Server on port {settings.APP_PORT}...")
    uvicorn.run("main:app", host="0.0.0.0", port=settings.APP_PORT, reload=False, workers=1)
