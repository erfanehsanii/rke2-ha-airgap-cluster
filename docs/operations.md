# Operations

## Safe configuration change

1. Record the reason, affected nodes, risk, validation, and rollback.
2. Snapshot embedded etcd before control-plane changes.
3. Validate YAML and search for unresolved placeholders.
4. Apply changes to one node at a time.
5. For workers, drain before restart and uncordon only after validation.
6. For control-plane nodes, preserve etcd quorum and never restart a majority together.
7. Run `scripts/validate-cluster.sh` after each node.

## Health signals

- Kubernetes `/readyz` returns successful checks.
- All expected nodes are `Ready`.
- Embedded etcd has three healthy members.
- CoreDNS, Canal, kube-proxy and metrics-server are healthy.
- No unexpected warning events or pending pods exist.
- Persistent volumes remain bound.

## Configuration ownership

Store reusable configuration in Git. Deliver tokens, certificates and registry credentials through a secure store. Store snapshots in encrypted, access-controlled, off-node storage.

## Routine checks

### Daily

- Confirm API and monitoring alerts are healthy.
- Review unexpected warning events and node conditions.
- Check `/var` capacity on servers and workers.
- Confirm the most recent scheduled snapshot succeeded.

### Weekly

- Review certificate-expiration horizons.
- Review failed pods, restart trends and persistent-volume state.
- Confirm offline backup copies meet retention requirements.
- Review administrative access and recent high-risk audit events.

### Periodically

- Test load-balancer failover.
- Perform an isolated snapshot restore drill.
- Verify offline artifact inventories and checksum sources.
- Review RKE2 support status and upgrade candidates.
- Re-run secret and configuration-drift scans.

## Worker maintenance

1. Confirm enough healthy capacity exists elsewhere.
2. Cordon and drain the worker according to workload disruption budgets.
3. Perform one scoped change.
4. Start or restart `rke2-agent` only when required.
5. Confirm node readiness, system DaemonSets, DNS and a test workload.
6. Uncordon the worker.
7. Record evidence and close the change.

Local-path volumes can prevent transparent rescheduling; inspect storage placement before draining.

## Server maintenance

Never stop a majority of embedded-etcd members. Maintain API load-balancer health, work on one server, validate quorum, and only then proceed. Snapshot creation is a prerequisite for changes that can affect datastore compatibility.

## Node removal

Drain application workloads, remove the Kubernetes node through the approved process, and verify etcd membership before removing a server. Deleting a node object does not necessarily remove an etcd member or clean host data. Preserve evidence and use the release-specific RKE2 removal procedure.

## Change record template

Every operational change should record:

- Reason and owner
- Affected nodes and services
- Preconditions and backup reference
- Exact change
- Expected validation results
- Abort conditions
- Rollback steps
- Actual outcome and evidence
