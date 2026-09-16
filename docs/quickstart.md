# Quick start

## Prerequisites

- Supported 64-bit Linux hosts using systemd
- Three control-plane nodes for etcd quorum
- One or more worker nodes
- A stable TCP load-balancer endpoint for ports `6443` and `9345`
- Offline RKE2 binary and image archives verified against a trusted checksum manifest
- Passwordless administrative access or an equivalent configuration-management workflow
- A securely generated RKE2 token distributed outside Git

## Workflow

1. Copy `config/modules-load/rke2.conf` and `config/sysctl/90-rke2.conf` into the appropriate operating-system directories and apply them.
2. Place the verified offline archives under `/opt/rke2-offline-bundle/rke2/`.
3. Create `/etc/rancher/rke2/token` with mode `0600` through your secret-management process.
4. Copy and customize the initial server example. Remove every `<PLACEHOLDER>`.
5. Run `scripts/preflight-check.sh`.
6. Validate installation arguments without changes by omitting `--apply`.
7. Install the first server, validate it, and then join the other servers one at a time.
8. Join workers one at a time and validate scheduling and networking.

Never execute an example against production without peer review and an approved rollback plan.
