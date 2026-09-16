#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=lib/common.sh
source "$ROOT_DIR/scripts/lib/common.sh"

usage() {
  cat <<'EOF'
Guided RKE2 node setup

Usage:
  setup-node.sh [options]

Options:
  --role init|join|agent       Node role; prompted when omitted
  --fixed-address VALUE        Stable VIP, IP, or DNS name; prompted when omitted
  --dns-san NAME               Optional additional DNS SAN for server roles
  --node-name NAME             Optional node-name override; OS hostname is the default
  --config FILE                Output path (default: /etc/rancher/rke2/config.yaml)
  --force-config               Replace an existing generated configuration
  --generate-only              Generate and display configuration; skip host preflight
  --apply                      After validation, invoke the guarded installer
  -h, --help                   Show help

Without --apply, installation is not performed.
EOF
}

role=""
fixed_address=""
dns_san=""
node_name=""
config=/etc/rancher/rke2/config.yaml
force_config=0
generate_only=0
apply=0

while (($#)); do
  case "$1" in
    --role) role=${2:-}; shift 2 ;;
    --fixed-address) fixed_address=${2:-}; shift 2 ;;
    --dns-san) dns_san=${2:-}; shift 2 ;;
    --node-name) node_name=${2:-}; shift 2 ;;
    --config) config=${2:-}; shift 2 ;;
    --force-config) force_config=1; shift ;;
    --generate-only) generate_only=1; shift ;;
    --apply) apply=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

choose_role() {
  local answer
  printf 'Select this node role:\n  1) First server\n  2) Additional server\n  3) Worker\nChoice: ' >&2
  read -r answer
  case "$answer" in
    1) role=init ;;
    2) role=join ;;
    3) role=agent ;;
    *) die 'role choice must be 1, 2, or 3' ;;
  esac
}

[[ -n "$role" ]] || choose_role
[[ "$role" == init || "$role" == join || "$role" == agent ]] || die '--role must be init, join, or agent'
! ((generate_only && apply)) || die '--generate-only and --apply cannot be used together'

if [[ -z "$fixed_address" ]]; then
  printf 'Fixed registration IP, VIP, or DNS name: ' >&2
  read -r fixed_address
fi
[[ -n "$fixed_address" ]] || die 'fixed address is required'
[[ "$fixed_address" != *://* && "$fixed_address" != *'/'* && "$fixed_address" != *[[:space:]]* ]] \
  || die 'provide only an IP, VIP, or DNS name; do not include a URL scheme, port, path, or spaces'

if [[ "$role" != agent && -z "$dns_san" && -t 0 ]]; then
  printf 'Optional additional DNS SAN (press Enter to skip): ' >&2
  read -r dns_san
fi
if [[ -n "$dns_san" ]]; then
  [[ "$role" != agent ]] || die '--dns-san applies only to server roles'
  [[ "$dns_san" != *://* && "$dns_san" != *'/'* && "$dns_san" != *[[:space:]]* ]] \
    || die 'DNS SAN must be a hostname without scheme, port, path, or spaces'
fi

if [[ -z "$node_name" && -t 0 ]]; then
  printf 'Optional Kubernetes node name (press Enter to use %s): ' "$(hostname -s)" >&2
  read -r node_name
fi

printf '\nConfiguration summary\n'
printf '  Role:             %s\n' "$role"
printf '  Fixed address:    %s\n' "$fixed_address"
printf '  Additional DNS:   %s\n' "${dns_san:-not configured}"
printf '  Node name:        %s\n' "${node_name:-OS hostname ($(hostname -s))}"
printf '  Configuration:    %s\n\n' "$config"

generator=("$ROOT_DIR/scripts/generate-config.sh" --role "$role" --output "$config")
if [[ "$role" == join || "$role" == agent ]]; then
  generator+=(--endpoint "https://${fixed_address}:9345")
fi
if [[ "$role" != agent ]]; then
  generator+=(--tls-san "$fixed_address")
  [[ -z "$dns_san" || "$dns_san" == "$fixed_address" ]] || generator+=(--tls-san "$dns_san")
fi
[[ -z "$node_name" ]] || generator+=(--node-name "$node_name")
((force_config == 0)) || generator+=(--force)

"${generator[@]}"

printf '\nGenerated configuration (contains no token value):\n'
sed 's/^/  /' "$config"

if ((generate_only)); then
  log 'Generation-only mode complete; no preflight or installation was performed'
  exit 0
fi

require_root
"$ROOT_DIR/scripts/preflight-check.sh"

if [[ "$role" == agent ]]; then
  installer=("$ROOT_DIR/scripts/install-agent.sh" --config "$config")
else
  installer=("$ROOT_DIR/scripts/install-server.sh" --role "$role" --config "$config")
fi

"${installer[@]}"

if ((apply == 0)); then
  printf '\nDry run passed. Review the configuration, then apply with:\n  sudo %q' "$0"
  printf ' --role %q --fixed-address %q --config %q --force-config --apply' "$role" "$fixed_address" "$config"
  [[ -z "$dns_san" ]] || printf ' --dns-san %q' "$dns_san"
  [[ -z "$node_name" ]] || printf ' --node-name %q' "$node_name"
  printf '\n'
  exit 0
fi

"${installer[@]}" --apply

if [[ "$role" == agent ]]; then
  printf '\nVerify locally:\n  sudo systemctl is-active rke2-agent\n'
  printf 'Then confirm this node is Ready from an RKE2 server.\n'
else
  printf '\nVerify this server before adding another node:\n'
  printf '  sudo systemctl is-active rke2-server\n'
  printf '  sudo %q\n' "$ROOT_DIR/scripts/validate-cluster.sh"
fi
