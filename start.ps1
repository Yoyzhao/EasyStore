$ErrorActionPreference = "Stop"
Write-Host "Starting EasyStore..."

$BASE_DIR = $PSScriptRoot

Write-Host "Building Frontend..."
Set-Location -Path (Join-Path $BASE_DIR "web")
npm run build

Write-Host "Starting Backend..."
Set-Location -Path (Join-Path $BASE_DIR "server")
if (-Not (Test-Path "venv")) {
    Write-Host "Creating Virtual Environment..."
    python -m venv venv
    .\venv\Scripts\Activate.ps1
    pip install -r requirements.txt
    pip install "bcrypt<4.0.0"
} else {
    .\venv\Scripts\Activate.ps1
}

Write-Host "Starting Server..."
Start-Process -NoNewWindow -FilePath "python" -ArgumentList "main.py"

Start-Sleep -Seconds 3
Start-Process "http://127.0.0.1:8000"
