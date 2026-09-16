#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$ROOT_DIR/scripts/lib/common.sh"
snapshot=""; apply=0
while (($#)); do
  case "$1" in
    --snapshot) snapshot=${2:-}; shift 2 ;;
    --apply) apply=1; shift ;;
    -h|--help) printf 'Usage: %s --snapshot FILE [--apply]\n' "$0"; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done
require_file "$snapshot"
[[ -s "$snapshot" ]] || die "snapshot is empty"
sha256sum "$snapshot"
if ((apply == 0)); then
  log "Dry validation only. Review docs/backup-and-recovery.md before using --apply."
  exit 0
fi
require_root
confirm_exact RESTORE_ETCD "DESTRUCTIVE: this resets the local RKE2 server from the selected snapshot. Confirm quorum-recovery procedure and stop other servers first."
systemctl stop rke2-server
rke2 server --cluster-reset --cluster-reset-restore-path "$snapshot"
systemctl start rke2-server
log "Local reset completed. Follow the documented multi-server rejoin sequence and validate the API."
