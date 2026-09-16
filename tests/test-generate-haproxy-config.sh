#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

"$ROOT_DIR/scripts/generate-haproxy-config.sh" \
  --bind-address 198.51.100.10 \
  --server rke2-server-01=192.0.2.11 \
  --server rke2-server-02=192.0.2.12 \
  --server rke2-server-03=192.0.2.13 \
  --server rke2-server-04=192.0.2.14 \
  --server rke2-server-05=192.0.2.15 \
  --output "$tmp_dir/haproxy.cfg"

grep -q '^  bind 198.51.100.10:6443$' "$tmp_dir/haproxy.cfg"
grep -q '^  bind 198.51.100.10:9345$' "$tmp_dir/haproxy.cfg"
[[ $(grep -c '^  server .*:6443 check$' "$tmp_dir/haproxy.cfg") -eq 5 ]]
[[ $(grep -c '^  server .*:9345 check$' "$tmp_dir/haproxy.cfg") -eq 5 ]]
printf 'PASS generated HAProxy configuration for five servers\n'

if "$ROOT_DIR/scripts/generate-haproxy-config.sh" \
  --bind-address 198.51.100.10 \
  --server duplicate=192.0.2.11 \
  --server duplicate=192.0.2.12 \
  --output "$tmp_dir/invalid.cfg" >/dev/null 2>&1; then
  printf 'FAIL duplicate HAProxy server name was accepted\n' >&2
  exit 1
fi
printf 'PASS rejected duplicate HAProxy server names\n'
