$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$webDir = Join-Path $projectRoot 'web'
$serverDir = Join-Path $projectRoot 'server'
$electronDir = Join-Path $projectRoot 'electron'
$stageDir = Join-Path $electronDir '.stage'
$frontendStageDir = Join-Path $stageDir 'renderer'
$backendStageDir = Join-Path $stageDir 'backend'
$tmpDir = Join-Path $projectRoot '.tmp'
$pythonDistDir = Join-Path $tmpDir 'python-dist'
$pyInstallerWorkDir = Join-Path $tmpDir 'pyinstaller'
$venvDir = Join-Path $serverDir 'venv'
$venvPython = Join-Path $venvDir 'Scripts\python.exe'
$venvPip = Join-Path $venvDir 'Scripts\pip.exe'
$venvPyInstaller = Join-Path $venvDir 'Scripts\pyinstaller.exe'
$webDistDir = Join-Path $webDir 'dist'
$backendBundleDir = Join-Path $pythonDistDir 'easystore-server'
$electronPackagerOutDir = Join-Path $tmpDir 'electron-packager'
$electronPackagedAppDir = Join-Path $electronPackagerOutDir 'EasyStore-win32-x64'
$electronOutDir = Join-Path $electronDir 'out-manual'
$electronZipDir = Join-Path $electronOutDir 'zip'
$electronZipPath = Join-Path $electronZipDir 'EasyStore-win32-x64-1.0.0.zip'
$electronInstallerDir = Join-Path $electronOutDir 'make\squirrel.windows\x64'
$electronIconPath = Join-Path $electronDir 'build\icon.ico'

function Remove-DirectoryIfExists {
    param([string]$Path)

    if (Test-Path $Path) {
        $lastError = $null

        for ($attempt = 1; $attempt -le 5; $attempt++) {
            try {
                Remove-Item -Recurse -Force $Path -ErrorAction Stop
                return
            }
            catch {
                $lastError = $_
                Start-Sleep -Milliseconds (500 * $attempt)
            }
        }

        throw $lastError
    }
}

try {
    Remove-DirectoryIfExists $stageDir
    Remove-DirectoryIfExists $tmpDir
    New-Item -ItemType Directory -Force -Path $frontendStageDir | Out-Null
    New-Item -ItemType Directory -Force -Path $backendStageDir | Out-Null

    Push-Location $webDir
    try {
        npm install --legacy-peer-deps
        npm run build
    }
    finally {
        Pop-Location
    }

    if (-not (Test-Path $venvPython)) {
        Push-Location $serverDir
        try {
            python -m venv venv
        }
        finally {
            Pop-Location
        }
    }

    & $venvPython -m pip install --upgrade pip
    & $venvPip install -r (Join-Path $serverDir 'requirements.txt')

    Push-Location $serverDir
    try {
        & $venvPyInstaller `
            --noconfirm `
            --clean `
            --onedir `
            --name easystore-server `
            --hidden-import passlib.handlers.bcrypt `
            --distpath $pythonDistDir `
            --workpath $pyInstallerWorkDir `
            --specpath $tmpDir `
            easystore-server.py
    }
    finally {
        Pop-Location
    }

    Copy-Item -Recurse -Force (Join-Path $webDistDir '*') $frontendStageDir
    # 确保使用 * 复制目录内容，使得可执行文件直接在 backend 目录下
    Copy-Item -Recurse -Force (Join-Path $backendBundleDir '*') $backendStageDir

    Push-Location $electronDir
    try {
        if (-not $env:ELECTRON_MIRROR) {
            $env:ELECTRON_MIRROR = 'https://npmmirror.com/mirrors/electron/'
        }

        # 1. 安装依赖并生成图标
        npm install
        npm run build:icon

        # 2. 执行打包 (使用 Electron Forge)
        # Forge 会根据 forge.config.js 自动处理 .stage 中的 extraResources
        npm run make
    }
    finally {
        Pop-Location
    }
}
finally {
    # 6. 清理临时目录
    Remove-DirectoryIfExists $stageDir
    Remove-DirectoryIfExists $tmpDir
}
