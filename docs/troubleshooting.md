# Troubleshooting

| Symptom | First checks | Avoid |
|---|---|---|
| Node does not join | Registration endpoint `9345`, token-file permissions, time synchronization, server logs | Printing the token or uploading logs publicly |
| API unavailable | Load balancer `6443`, server service state, etcd quorum, certificate validity | Restarting all control planes together |
| Node `NotReady` | Kubelet status, Canal pods, CNI interfaces, disk pressure | Deleting CNI state without a recovery plan |
| DNS failures | CoreDNS pods/endpoints, pod networking, NetworkPolicy | Assuming DNS is broken before testing network reachability |
| Pods cannot start | Events, image availability, containerd storage, admission policy | Publishing registry endpoints or credentials |
| Disk pressure | `/var` usage, images, logs, snapshots and workload data | Deleting etcd data or active containerd content |
| Metrics missing | Listener binding, firewall path, Service selectors and endpoints | Opening metrics endpoints to untrusted networks |

Collect evidence before changes. Keep logs and diagnostic bundles private until sanitized.

## Evidence order

Use the least invasive evidence first:

1. API readiness and node conditions
2. Events and system-pod state
3. Local service state and filesystem capacity
4. Network listeners and path tests
5. Private component logs
6. Configuration comparison against a healthy peer

Do not paste raw kubeconfigs, tokens, certificates, environment variables or complete logs into public issues.

## Node cannot join

Check that the node resolves and reaches the registration endpoint on `9345`, the token file exists with strict permissions, clocks are synchronized, the configured node name is unique, and the joining node uses a compatible RKE2 version. Confirm the load balancer has healthy registration backends.

## API endpoint unavailable

Test the load-balancer listener and each server backend separately from an authorized network. Confirm at least two etcd members and the server services are healthy. If quorum is uncertain, stop making uncontrolled changes and follow the recovery decision process.

## Node is NotReady

Inspect node conditions for disk, memory, PID or network pressure. Confirm `rke2-agent` or `rke2-server` is active, containerd can operate, required modules are loaded, sysctl values are consistent, and the Canal pod assigned to the node is healthy.

## DNS failure

Separate service-discovery failure from general networking failure. Test pod-to-pod connectivity, the Kubernetes DNS service IP, CoreDNS endpoints and a query from a known-good test pod. Inspect NetworkPolicy only after verifying the basic path.

## Disk pressure

Identify whether images, container logs, audit logs, snapshots or workload-local data account for growth. Use supported pruning and retention procedures. Never delete embedded-etcd database files or active containerd directories manually.

## Escalation package

Provide sanitized timestamps, affected placeholders, versions, conditions, relevant events, expected versus observed behavior, actions already attempted, and rollback status. Keep raw evidence in the restricted incident workspace.
