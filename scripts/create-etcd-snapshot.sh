#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$ROOT_DIR/scripts/lib/common.sh"
require_root
require_command rke2
systemctl is-active --quiet rke2-server || die "rke2-server is not active"
name="manual-$(date -u +%Y%m%dT%H%M%SZ)"
rke2 etcd-snapshot save --name "$name"
rke2 etcd-snapshot list
log "Snapshot requested: $name. Copy it to protected off-node storage and validate restoration in a non-production environment."
