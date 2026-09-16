#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  generate-config.sh --role init|join|agent --output FILE [options]

Required by role:
  init:          at least one --tls-san (the fixed endpoint)
  join:          --endpoint URL and at least one --tls-san
  agent:         --endpoint URL

Options:
  --endpoint URL       Registration URL, for example https://198.51.100.10:9345
  --tls-san VALUE      Server certificate IP/DNS SAN; repeat as needed
  --node-name NAME     Optional; omit to use the operating-system hostname
  --output FILE        Destination configuration file
  --force              Replace an existing output file
EOF
}

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
quote_yaml() { printf "'%s'" "${1//\'/\'\'}"; }

role=""
endpoint=""
node_name=""
output=""
force=0
tls_sans=()

while (($#)); do
  case "$1" in
    --role) role=${2:-}; shift 2 ;;
    --endpoint) endpoint=${2:-}; shift 2 ;;
    --tls-san) tls_sans+=("${2:-}"); shift 2 ;;
    --node-name) node_name=${2:-}; shift 2 ;;
    --output) output=${2:-}; shift 2 ;;
    --force) force=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[[ "$role" == init || "$role" == join || "$role" == agent ]] || die '--role must be init, join, or agent'
[[ -n "$output" ]] || die '--output is required'
[[ "$output" == /* ]] || die '--output must be an absolute path'
[[ ! -e "$output" || $force -eq 1 ]] || die "output exists; use --force to replace it: $output"

if [[ "$role" == join || "$role" == agent ]]; then
  [[ "$endpoint" =~ ^https://[^/[:space:]]+:9345$ ]] || die '--endpoint must look like https://HOST_OR_IP:9345'
elif [[ -n "$endpoint" ]]; then
  die '--endpoint is not used for the init role'
fi

if [[ "$role" == init || "$role" == join ]]; then
  ((${#tls_sans[@]} > 0)) || die 'server roles require at least one --tls-san for the fixed endpoint'
fi

for value in "$endpoint" "$node_name" "${tls_sans[@]}"; do
  [[ "$value" != *$'\n'* && "$value" != *$'\r'* ]] || die 'values must not contain newlines'
done

umask 077
output_dir=$(dirname "$output")
if [[ ! -d "$output_dir" ]]; then
  install -d -m 0700 "$output_dir"
fi
tmp=$(mktemp "${output}.tmp.XXXXXX")
trap 'rm -f "$tmp"' EXIT

if [[ "$role" != init ]]; then
  printf 'server: %s\n' "$(quote_yaml "$endpoint")" >>"$tmp"
fi
printf 'token-file: /etc/rancher/rke2/token\n' >>"$tmp"
if [[ -n "$node_name" ]]; then
  printf 'node-name: %s\n' "$(quote_yaml "$node_name")" >>"$tmp"
fi

if [[ "$role" != agent ]]; then
  cat >>"$tmp" <<'EOF'

cni:
  - canal
EOF
  printf '\ntls-san:\n' >>"$tmp"
  for san in "${tls_sans[@]}"; do
    [[ -n "$san" ]] || die '--tls-san cannot be empty'
    printf '  - %s\n' "$(quote_yaml "$san")" >>"$tmp"
  done
  cat >>"$tmp" <<'EOF'

write-kubeconfig-mode: "0600"
etcd-expose-metrics: true

kube-apiserver-arg:
  - audit-log-path=/var/lib/rancher/rke2/server/logs/audit.log
  - audit-log-maxage=30
  - audit-log-maxbackup=10
  - audit-log-maxsize=100

kube-controller-manager-arg:
  - metrics-bind-address=0.0.0.0

kube-scheduler-arg:
  - bind-address=0.0.0.0
EOF
fi

cat >>"$tmp" <<'EOF'

kubelet-arg:
  - container-log-max-size=50Mi
  - container-log-max-files=5

kube-proxy-arg:
  - metrics-bind-address=0.0.0.0:10249
EOF

install -m 0600 "$tmp" "$output"
printf 'Wrote %s configuration to %s\n' "$role" "$output"
