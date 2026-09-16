# Monitoring and alerting

## Monitoring goals

Monitoring should answer four questions:

1. Can clients reach the Kubernetes API?
2. Is the control plane maintaining quorum and processing work?
3. Can nodes run and network workloads?
4. Can operators recover the cluster within the required recovery objectives?

## Recommended signals

| Layer | Signals | Example alert intent |
|---|---|---|
| Load balancer | Backend health for `6443` and `9345` | No healthy API or registration backend |
| API server | Availability, latency, error rate, inflight requests | Sustained errors or latency breach |
| etcd | Member health, leader changes, proposal failures, database size, fsync latency | Lost member, no leader or slow disk |
| Nodes | Ready state, pressure conditions, filesystem use, clock drift | Node unavailable or `/var` capacity risk |
| Kubelet/runtime | Pod start failures, runtime operations and PLEG health | Workloads cannot start reliably |
| Canal | DaemonSet readiness and network errors | Node networking degraded |
| CoreDNS | Availability, error rate and query latency | Cluster service discovery degraded |
| kube-proxy | Target availability and sync failures | Service networking configuration degraded |
| Certificates | Expiration horizon | Certificate renewal required |
| Recovery | Snapshot age, off-node copy, last successful restore drill | Recovery point or proof is stale |

## Target identity

Use stable labels such as cluster, role, node and environment. Avoid embedding organization-sensitive values in public dashboards. Alert annotations should identify the affected component and node while providing a short first-response action.

## Metrics exposure

This reference binds several component metrics to routable interfaces to support central monitoring. That decision must be paired with network restrictions. Do not expose etcd, controller-manager, scheduler, kubelet or kube-proxy metrics directly to untrusted networks.

## Validation

- Confirm every intended target is present and `up`.
- Confirm Service selectors produce endpoints.
- Test alerts in a controlled environment.
- Ensure missing-target alerts include enough identity for responders.
- Validate dashboards across normal, degraded and recovery states.
