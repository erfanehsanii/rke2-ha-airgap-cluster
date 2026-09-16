#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

"$ROOT_DIR/scripts/setup-node.sh" \
  --role init \
  --fixed-address 198.51.100.10 \
  --dns-san rke2-api.example.com \
  --node-name rke2-server-01 \
  --config "$tmp_dir/init.yaml" \
  --generate-only

"$ROOT_DIR/scripts/setup-node.sh" \
  --role join \
  --fixed-address 198.51.100.10 \
  --config "$tmp_dir/join.yaml" \
  --generate-only

"$ROOT_DIR/scripts/setup-node.sh" \
  --role agent \
  --fixed-address 198.51.100.10 \
  --config "$tmp_dir/agent.yaml" \
  --generate-only

python3 - "$tmp_dir" <<'PY'
from pathlib import Path
import sys
import yaml

root = Path(sys.argv[1])
init = yaml.safe_load((root / "init.yaml").read_text())
join = yaml.safe_load((root / "join.yaml").read_text())
agent = yaml.safe_load((root / "agent.yaml").read_text())

assert "server" not in init
assert init["node-name"] == "rke2-server-01"
assert init["tls-san"] == ["198.51.100.10", "rke2-api.example.com"]
assert join["server"] == "https://198.51.100.10:9345"
assert agent["server"] == "https://198.51.100.10:9345"
assert "tls-san" not in agent
print("PASS guided setup generated all node roles")
PY

if "$ROOT_DIR/scripts/setup-node.sh" \
  --role agent \
  --fixed-address 198.51.100.10 \
  --dns-san invalid.example.com \
  --config "$tmp_dir/invalid-agent.yaml" \
  --generate-only >/dev/null 2>&1; then
  printf 'FAIL agent unexpectedly accepted --dns-san\n' >&2
  exit 1
fi

if "$ROOT_DIR/scripts/setup-node.sh" \
  --role init \
  --fixed-address https://198.51.100.10:9345 \
  --config "$tmp_dir/invalid-address.yaml" \
  --generate-only >/dev/null 2>&1; then
  printf 'FAIL wizard unexpectedly accepted a URL as a fixed address\n' >&2
  exit 1
fi

printf 'PASS guided setup rejected unsafe role/address combinations\n'
