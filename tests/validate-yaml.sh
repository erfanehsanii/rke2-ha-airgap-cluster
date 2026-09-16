#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"
mapfile -d '' files < <(find . -type f \( -name '*.yaml' -o -name '*.yml' \) -print0)
((${#files[@]})) || { printf 'No YAML files found\n' >&2; exit 1; }
python3 - "${files[@]}" <<'PY'
import sys
try:
    import yaml
except ImportError:
    raise SystemExit("PyYAML is required: python3 -m pip install pyyaml")
for path in sys.argv[1:]:
    with open(path,encoding="utf-8") as f:
        list(yaml.safe_load_all(f))
    print(f"PASS {path}")
PY
