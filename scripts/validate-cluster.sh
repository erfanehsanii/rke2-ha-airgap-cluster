#!/usr/bin/env bash
set -Eeuo pipefail

KUBECTL=${KUBECTL:-kubectl}
KUBECONFIG=${KUBECONFIG:-/etc/rancher/rke2/rke2.yaml}
export KUBECONFIG

command -v "$KUBECTL" >/dev/null || { printf 'kubectl not found\n' >&2; exit 1; }
fail=0
run() { printf '\n### %s\n' "$1"; shift; "$@" || fail=1; }
run "API readiness" "$KUBECTL" get --raw='/readyz?verbose'
run "Nodes" "$KUBECTL" get nodes -o wide
run "Unhealthy pods" bash -c 'kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded'
run "Control-plane components" "$KUBECTL" get pods -n kube-system -o wide
run "Storage classes" "$KUBECTL" get storageclasses
run "Persistent volumes" "$KUBECTL" get persistentvolumes
run "Recent warning events" bash -c 'kubectl get events -A --field-selector=type=Warning --sort-by=.lastTimestamp | tail -n 50'
exit "$fail"
