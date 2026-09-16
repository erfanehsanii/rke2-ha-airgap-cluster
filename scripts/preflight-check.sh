#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=lib/common.sh
source "$ROOT_DIR/scripts/lib/common.sh"

failures=0
check() {
  local description=$1; shift
  if "$@" >/dev/null 2>&1; then printf 'PASS  %s\n' "$description"
  else printf 'FAIL  %s\n' "$description"; failures=$((failures+1)); fi
}

check "64-bit x86 architecture" test "$(uname -m)" = x86_64
check "systemd is available" command -v systemctl
check "overlay module available" modprobe -n overlay
check "br_netfilter module available" modprobe -n br_netfilter
check "IPv4 forwarding enabled" test "$(sysctl -n net.ipv4.ip_forward 2>/dev/null)" = 1
check "bridge IPv4 filtering enabled" test "$(sysctl -n net.bridge.bridge-nf-call-iptables 2>/dev/null)" = 1
check "RKE2 configuration directory exists" test -d /etc/rancher/rke2
check "RKE2 token exists" test -s /etc/rancher/rke2/token
check "RKE2 token is not group/world readable" bash -c 'mode=$(stat -c %a /etc/rancher/rke2/token 2>/dev/null); [[ "$mode" == 600 || "$mode" == 400 ]]'
check "offline RKE2 binary archive exists" test -s /opt/rke2-offline-bundle/rke2/rke2.linux-amd64.tar.gz
check "offline RKE2 image archive exists" test -s /opt/rke2-offline-bundle/rke2/rke2-images.linux-amd64.tar.zst

if ((failures)); then die "$failures preflight check(s) failed"; fi
log "All preflight checks passed"
