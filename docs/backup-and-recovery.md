# Backup and recovery

RKE2 embedded-etcd snapshots contain cluster state and must be treated as confidential data.

## Backup

1. Run `scripts/create-etcd-snapshot.sh` on a healthy server.
2. Record its checksum with `scripts/validate-etcd-snapshot.sh`.
3. Copy it to encrypted off-node storage.
4. Apply retention and access controls.
5. Test restoration regularly in an isolated environment.

## Recovery guardrails

- Confirm the selected recovery point and checksum.
- Preserve the failed cluster for forensic review when possible.
- Stop other server nodes before a cluster reset.
- Reset one designated server from the snapshot.
- Rejoin additional servers according to the RKE2 recovery procedure.
- Validate workloads, RBAC, storage and application state.

`restore-etcd-snapshot.sh` performs no reset unless `--apply` is supplied and the exact confirmation phrase is entered. A checksum check alone does not prove that a snapshot is restorable.

## Suggested evidence record

For every protected snapshot, record its UTC creation time, originating cluster placeholder, RKE2 version, SHA-256 checksum, encrypted storage location, retention expiry and last successful restore drill. Do not put the storage credentials or production endpoint in Git.

## Restore drill success criteria

- The snapshot checksum matches the recorded value.
- A clean isolated environment can start from the snapshot.
- Kubernetes API access is restored.
- Expected namespaces, RBAC and workload objects exist.
- Secret values are never copied into the drill report.
- Storage-dependent applications are validated through their own recovery plans.
- Recovery duration and data-loss window are compared with agreed objectives.

## Important boundary

An etcd snapshot restores Kubernetes state. It does not back up application data stored in persistent volumes, external databases or object storage. Coordinate platform and application recovery plans.
