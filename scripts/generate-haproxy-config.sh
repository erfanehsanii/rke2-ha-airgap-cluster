#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  generate-haproxy-config.sh --bind-address ADDRESS --server NAME=ADDRESS \
    [--server NAME=ADDRESS ...] --output FILE [--force]

Example:
  generate-haproxy-config.sh \
    --bind-address 198.51.100.10 \
    --server rke2-server-01=192.0.2.11 \
    --server rke2-server-02=192.0.2.12 \
    --server rke2-server-03=192.0.2.13 \
    --output /etc/haproxy/haproxy.cfg
EOF
}

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

bind_address=""
output=""
force=0
servers=()

while (($#)); do
  case "$1" in
    --bind-address) bind_address=${2:-}; shift 2 ;;
    --server) servers+=("${2:-}"); shift 2 ;;
    --output) output=${2:-}; shift 2 ;;
    --force) force=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[[ -n "$bind_address" ]] || die '--bind-address is required'
[[ "$bind_address" != *[[:space:]]* && "$bind_address" != *'/'* ]] || die 'invalid bind address'
((${#servers[@]} > 0)) || die 'provide at least one --server NAME=ADDRESS'
[[ "$output" == /* ]] || die '--output must be an absolute path'
[[ ! -e "$output" || $force -eq 1 ]] || die "output exists; use --force to replace it: $output"

declare -A seen_names=()
for item in "${servers[@]}"; do
  [[ "$item" == *=* ]] || die "server must use NAME=ADDRESS: $item"
  name=${item%%=*}
  address=${item#*=}
  [[ "$name" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || die "invalid server name: $name"
  [[ -n "$address" && "$address" != *[[:space:]]* && "$address" != *'/'* ]] || die "invalid server address: $address"
  [[ -z ${seen_names[$name]:-} ]] || die "duplicate server name: $name"
  seen_names[$name]=1
done

output_dir=$(dirname "$output")
if [[ ! -d "$output_dir" ]]; then
  install -d -m 0755 "$output_dir"
fi
tmp=$(mktemp "${output}.tmp.XXXXXX")
trap 'rm -f "$tmp"' EXIT

cat >"$tmp" <<EOF
global
  log stdout format raw local0
  maxconn 4096

defaults
  mode tcp
  log global
  option tcplog
  timeout connect 5s
  timeout client 50s
  timeout server 50s

frontend kubernetes_api
  bind ${bind_address}:6443
  default_backend kubernetes_api_servers

backend kubernetes_api_servers
  option tcp-check
  balance roundrobin
EOF

for item in "${servers[@]}"; do
  printf '  server %s %s:6443 check\n' "${item%%=*}" "${item#*=}" >>"$tmp"
done

cat >>"$tmp" <<EOF

frontend rke2_registration
  bind ${bind_address}:9345
  default_backend rke2_registration_servers

backend rke2_registration_servers
  option tcp-check
  balance roundrobin
EOF

for item in "${servers[@]}"; do
  printf '  server %s %s:9345 check\n' "${item%%=*}" "${item#*=}" >>"$tmp"
done

install -m 0644 "$tmp" "$output"
printf 'Wrote HAProxy configuration with %d RKE2 server(s) to %s\n' "${#servers[@]}" "$output"
