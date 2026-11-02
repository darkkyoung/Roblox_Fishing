#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
luau-analyze src/shared/*.lua src/server/*.lua src/client/*.lua
for source in src/shared/*.lua src/server/*.lua src/client/*.lua; do
    luau-compile "$source" > /dev/null
done
python3 scripts/run_tests.py
luau tests/functional.spec.luau
python3 tests/serialization.spec.py
python3 scripts/test_boot.py
python3 scripts/validate_place.py
