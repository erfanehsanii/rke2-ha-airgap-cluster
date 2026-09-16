# Upgrades and rollback

## Order

1. Review RKE2 and Kubernetes release notes and version-skew rules.
2. Validate offline artifact checksums.
3. Take and copy an etcd snapshot off-node.
4. Upgrade one non-bootstrap control-plane node.
5. Validate API, etcd, networking and workloads.
6. Upgrade the remaining control-plane nodes one at a time.
7. Drain and upgrade workers one at a time.

Do not skip Kubernetes minor versions unless the selected RKE2 release explicitly supports it.

## Rollback

Binary rollback may not reverse datastore migrations. Stop after the first failed node, retain logs privately, and consult the release-specific rollback guidance. Use an etcd restore only when ordinary binary rollback is insufficient and the recovery plan explicitly calls for it.

## Per-node validation gate

After each node, confirm service state, reported version, node readiness, etcd health for servers, Canal and kube-proxy readiness, DNS, storage objects and an approved workload smoke test. Do not continue while the cluster is degraded.

## Abort conditions

- etcd loses a healthy member beyond the node under maintenance
- API readiness fails
- System networking or DNS becomes unavailable
- Nodes report unexpected pressure or readiness transitions
- Persistent volumes or critical workloads become unhealthy
- The new version differs from the approved artifact manifest

## Rollback evidence

Record the node, old and new versions, artifact checksums, failure signal, decision owner, actions taken and final cluster state. Keep raw logs private until sanitized.
