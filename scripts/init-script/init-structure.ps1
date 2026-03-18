# init-structure.ps1
# 自动创建符合 dir-rules.md 的项目目录结构

$dirs = @(
    "docs/prototype",
    "docs/tech",
    "docs/test",
    "docs/deploy",
    "docs/plan",
    "docs/debug",
    "docs/prd",
    "data/db",
    "data/app_logs",
    "server/app/api/v1/endpoints",
    "server/app/core",
    "server/app/db",
    "server/app/models",
    "server/app/schemas",
    "server/tests",
    "web/public",
    "web/src/api",
    "web/src/assets",
    "web/src/components",
    "web/src/router",
    "web/src/store",
    "web/src/views",
    "scripts/deploy-script",
    "scripts/sql-script",
    "scripts/test-script",
    "scripts/init-script",
    "build"
)

foreach ($d in $dirs) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Force -Path $d | Out-Null
        Write-Host "Created: $d"
    }
}

# 初始化 bug-record.md
$bugFile = "docs/debug/bug-record.md"
if (-not (Test-Path $bugFile)) {
    $header = "# Bug Fix Record`n`n| ID | Date | Issue | Cause | Solution | Status |`n|---|---|---|---|---|---|`n"
    $header | Out-File -Encoding utf8 $bugFile
    Write-Host "Created: $bugFile"
}

# 初始化 project-dev-plan.md
$planFile = "docs/plan/project-dev-plan.md"
if (-not (Test-Path $planFile)) {
    $planHeader = "# Project Development Plan`n`n## Phase 1: Prototype`n- [ ] Task 1`n`n## Phase 2: Frontend`n`n## Phase 3: Backend`n"
    $planHeader | Out-File -Encoding utf8 $planFile
    Write-Host "Created: $planFile"
}

Write-Host "Project structure initialized successfully."