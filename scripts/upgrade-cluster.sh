#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$ROOT_DIR/scripts/lib/common.sh"
role=""; apply=0
while (($#)); do
  case "$1" in
    --role) role=${2:-}; shift 2 ;;
    --apply) apply=1; shift ;;
    -h|--help) printf 'Usage: %s --role server|agent [--apply]\n' "$0"; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done
[[ "$role" == server || "$role" == agent ]] || die "--role must be server or agent"
service="rke2-$role"
require_file /opt/rke2-offline-bundle/rke2/rke2.linux-amd64.tar.gz
require_file /opt/rke2-offline-bundle/rke2/rke2-images.linux-amd64.tar.zst
sha256sum /opt/rke2-offline-bundle/rke2/rke2.linux-amd64.tar.gz /opt/rke2-offline-bundle/rke2/rke2-images.linux-amd64.tar.zst
if ((apply == 0)); then log "Artifacts found. Verify their hashes against a trusted manifest, snapshot etcd, drain this node, then use --apply."; exit 0; fi
require_root
confirm_exact UPGRADE_RKE2 "This replaces local RKE2 binaries and restarts $service. Upgrade one node at a time."
systemctl stop "$service"
install -m 0644 /opt/rke2-offline-bundle/rke2/rke2-images.linux-amd64.tar.zst /var/lib/rancher/rke2/agent/images/
tar -xzf /opt/rke2-offline-bundle/rke2/rke2.linux-amd64.tar.gz -C /
systemctl start "$service"
systemctl is-active --quiet "$service" || die "$service did not become active"
rke2 --version
log "Node upgraded; uncordon only after cluster validation"
