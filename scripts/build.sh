#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 scripts/generate_world.py
rojo build default.project.json -o build/FILAMENT-Fishing-0.2.rbxlx
rojo build default.project.json -o build/FILAMENT-Fishing-0.2.rbxl
python3 scripts/validate_place.py
