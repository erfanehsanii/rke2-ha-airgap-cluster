#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

"$ROOT_DIR/scripts/generate-config.sh" \
  --role init \
  --tls-san 198.51.100.10 \
  --tls-san rke2-api.example.com \
  --output "$tmp_dir/init.yaml"

"$ROOT_DIR/scripts/generate-config.sh" \
  --role join \
  --endpoint https://198.51.100.10:9345 \
  --tls-san 198.51.100.10 \
  --output "$tmp_dir/join.yaml"

"$ROOT_DIR/scripts/generate-config.sh" \
  --role agent \
  --endpoint https://198.51.100.10:9345 \
  --node-name rke2-worker-01 \
  --output "$tmp_dir/agent.yaml"

python3 - "$tmp_dir" <<'PY'
from pathlib import Path
import sys
import yaml

root = Path(sys.argv[1])
init = yaml.safe_load((root / "init.yaml").read_text())
join = yaml.safe_load((root / "join.yaml").read_text())
agent = yaml.safe_load((root / "agent.yaml").read_text())

assert "server" not in init
assert init["tls-san"] == ["198.51.100.10", "rke2-api.example.com"]
assert join["server"] == "https://198.51.100.10:9345"
assert agent["node-name"] == "rke2-worker-01"
assert "tls-san" not in agent
print("PASS generated init, join and agent configurations")
PY
