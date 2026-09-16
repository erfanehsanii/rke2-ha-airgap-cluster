# Educational animation storyboard

## Concept: “A worker joins an air-gapped RKE2 cluster”

The animation should teach a concrete flow in 45–60 seconds. It should use simple node icons, short labels and highlighted traffic paths rather than decorative motion.

| Scene | Visual | Teaching point |
|---:|---|---|
| 1 | Connected staging host downloads two version-pinned archives | Air-gapped does not mean unverified software |
| 2 | Checksum manifest validates the archives | Integrity is checked before transfer |
| 3 | Artifacts cross an approved transfer boundary | Offline delivery is controlled and auditable |
| 4 | Token arrives from a separate secure store | Secrets do not come from Git |
| 5 | Worker contacts the stable endpoint on `9345` | Registration is decoupled from one server |
| 6 | Load balancer selects a healthy server | HA hides individual server maintenance/failure |
| 7 | Worker starts containerd, kubelet, Canal and kube-proxy | Node services create compute and networking capability |
| 8 | Kubernetes reports the worker `Ready` | Readiness is verified, not assumed |
| 9 | A test pod schedules and resolves DNS | Validation includes workload behavior |
| 10 | Final frame shows snapshot, monitoring and audit icons | Installation leads into day-two operations |

## Optional follow-up animation

“One server fails, etcd keeps quorum” can show a three-member quorum, one failed member, continuing API traffic, and the one-node-at-a-time repair process. Avoid implying that two simultaneous member failures are safe.
