$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
python scripts/generate_world.py
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
rojo build default.project.json -o build/FILAMENT-Fishing-0.1.rbxlx
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
rojo build default.project.json -o build/FILAMENT-Fishing-0.1.rbxl
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
python scripts/validate_place.py
exit $LASTEXITCODE
