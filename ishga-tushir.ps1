$flutter = Join-Path $env:USERPROFILE "flutter\bin"
if (Test-Path $flutter) {
  $env:Path = "$flutter;" + $env:Path
}

Set-Location (Join-Path $PSScriptRoot "backend")

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
  Write-Error "Python topilmadi. Python 3 o'rnating."
  exit 1
}

python -c "import fastapi, uvicorn" 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host "Kerakli paketlar o'rnatilmoqda..."
  python -m pip install -r requirements.txt
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

$env:PORT = if ($env:PORT) { $env:PORT } else { "8080" }
Write-Host "TEZ FOOD FastAPI: http://localhost:$($env:PORT)"
python -m uvicorn main:app --host 0.0.0.0 --port $env:PORT
