# Design decisions and lessons learned

## Three embedded-etcd servers

Three members tolerate one member failure while keeping the system operationally understandable. Adding more members increases quorum and latency considerations and is not automatically better.

## Stable load-balanced endpoint

Nodes register through one stable endpoint rather than a particular server. This reduces coupling during server maintenance and replacement. Both API and registration ports must be health-checked and highly available.

## Canal CNI

Canal combines Flannel networking with Calico policy capabilities. The public example retains the observed CNI choice without claiming it is universally optimal.

## Air-gapped installation

Offline installation reduces runtime external dependency but increases supply-chain and lifecycle work. Artifacts must be downloaded on a trusted connected system, verified, transferred, inventoried and upgraded deliberately.

## File-based token reference

`token-file` avoids embedding a join token directly in the main YAML file. The token file remains sensitive and must be deployed outside Git with strict permissions.

## Audit-log rotation

Audit logging improves accountability but can consume storage and record sensitive metadata. Rotation bounds local growth; centralized retention and access policy remain environment-specific responsibilities.

## Routable metrics endpoints

Binding metrics to routable interfaces enables central Prometheus collection. It also widens the listening surface, so firewalling and monitoring-network restrictions are part of the same design decision.

## Local snapshots plus off-node copies

Local snapshots make creation fast but do not protect against node or site loss. The runbook therefore requires encrypted off-node copies and isolated restore drills.

## Dry-run-first scripts

Installation, upgrade and restore tooling validates prerequisites before mutation. High-risk actions require both `--apply` and a precise confirmation phrase. This does not replace peer review, but it reduces accidental execution.

## Configuration drift

The source environment revealed inconsistent inotify limits and one unnecessary enabled agent service on a server node. The public project converts that lesson into standardized sysctl configuration and explicit service-role handling.
