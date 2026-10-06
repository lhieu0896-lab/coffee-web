# Deploy Flutter web to GitHub Pages (main branch of coffee-web)
# Usage: .\deploy.ps1

$ErrorActionPreference = "Stop"
$REMOTE = "https://github.com/lhieu0896-lab/coffee-web.git"
$ROOT = $PSScriptRoot

Write-Host "==> Build Flutter web..." -ForegroundColor Cyan
Set-Location $ROOT
flutter build web --release --base-href "/coffee-web/"
if ($LASTEXITCODE -ne 0) { Write-Host "Build failed" -ForegroundColor Red; exit 1 }

$DEPLOY_DIR = Join-Path $env:TEMP "caphe-deploy"
if (Test-Path $DEPLOY_DIR) { Remove-Item -Recurse -Force $DEPLOY_DIR }

Write-Host "==> Clone nhanh main..." -ForegroundColor Cyan
git clone -q --branch main --single-branch $REMOTE $DEPLOY_DIR
Set-Location $DEPLOY_DIR
git rm -rq .
Copy-Item -Recurse -Force (Join-Path $ROOT "build\web\*") $DEPLOY_DIR
New-Item -ItemType File -Force ".nojekyll" | Out-Null
git add -A
git commit -q -m "deploy: update Flutter web build"
git push origin main

Set-Location $ROOT
Write-Host "==> Deploy xong! https://lhieu0896-lab.github.io/coffee-web/" -ForegroundColor Green
