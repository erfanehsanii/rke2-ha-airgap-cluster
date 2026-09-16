#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
if ! command -v mmdc >/dev/null 2>&1; then
  printf 'SKIP Mermaid CLI is not installed\n'
  exit 0
fi

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

python3 - "$ROOT_DIR" "$tmp_dir" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
output = Path(sys.argv[2])
count = 0
for markdown in root.rglob("*.md"):
    text = markdown.read_text(encoding="utf-8")
    for block in re.findall(r"^```mermaid\s*\n(.*?)^```\s*$", text, re.M | re.S):
        count += 1
        (output / f"diagram-{count:03d}.mmd").write_text(block, encoding="utf-8")
if count == 0:
    raise SystemExit("No Mermaid diagrams found")
print(count)
PY

count=0
for diagram in "$tmp_dir"/*.mmd; do
  count=$((count + 1))
  mmdc --input "$diagram" --output "${diagram%.mmd}.svg" --quiet
done
printf 'PASS rendered %d Mermaid diagrams\n' "$count"
