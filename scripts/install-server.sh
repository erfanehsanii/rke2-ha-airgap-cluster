#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=scripts/lib/common.sh
source "$ROOT_DIR/scripts/lib/common.sh"

usage() { printf 'Usage: %s --role init|join --config FILE [--apply]\n' "$0"; }
role=""; config=""; apply=0
while (($#)); do
  case "$1" in
    --role) role=${2:-}; shift 2 ;;
    --config) config=${2:-}; shift 2 ;;
    --apply) apply=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done
[[ "$role" == init || "$role" == join ]] || die "--role must be init or join"
require_file "$config"
require_file /etc/rancher/rke2/token
require_file /opt/rke2-offline-bundle/rke2/rke2.linux-amd64.tar.gz
require_file /opt/rke2-offline-bundle/rke2/rke2-images.linux-amd64.tar.zst
grep -Eq '<[A-Z0-9_]+>' "$config" && die "configuration still contains placeholders"
if [[ "$role" == init ]] && grep -Eq '^[[:space:]]*server:' "$config"; then
  die "init configuration must not contain server:"
fi
if [[ "$role" == join ]] && ! grep -Eq '^[[:space:]]*server:' "$config"; then
  die "join configuration requires server:"
fi

if ((apply == 0)); then
  log "Validation complete; no changes made. Re-run with --apply to install."
  exit 0
fi
require_root
confirm_exact INSTALL_RKE2 "This installs and starts an RKE2 server using $config."
install -d -m 0700 /etc/rancher/rke2 /var/lib/rancher/rke2/agent/images
if [[ "$(readlink -f "$config")" != /etc/rancher/rke2/config.yaml ]]; then
  install -m 0600 "$config" /etc/rancher/rke2/config.yaml
else
  chmod 0600 /etc/rancher/rke2/config.yaml
fi
install -m 0644 /opt/rke2-offline-bundle/rke2/rke2-images.linux-amd64.tar.zst /var/lib/rancher/rke2/agent/images/
tar -xzf /opt/rke2-offline-bundle/rke2/rke2.linux-amd64.tar.gz -C /
systemctl enable --now rke2-server
systemctl disable rke2-agent >/dev/null 2>&1 || true
log "RKE2 server started; validate cluster health before adding another server"
