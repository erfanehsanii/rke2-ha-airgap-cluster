# Quick start

## Recommended: guided setup

Run this from the cloned repository on each node:

```bash
sudo ./scripts/setup-node.sh
```

The wizard explains its choices, writes the configuration, displays it, validates the host and performs an installer dry run. It does not install RKE2 unless you run it with `--apply`.

Non-interactive examples:

```bash
# First server
sudo ./scripts/setup-node.sh --role init --fixed-address 198.51.100.10

# Additional server
sudo ./scripts/setup-node.sh --role join --fixed-address 198.51.100.10

# Worker
sudo ./scripts/setup-node.sh --role agent --fixed-address 198.51.100.10
```

Continue below if you want to understand and run every underlying command manually.

## Prerequisites

- Supported 64-bit Linux hosts using systemd
- An odd number of server nodes; three is recommended for HA
- Zero or more workers
- A stable TCP load-balancer endpoint for ports `6443` and `9345`
- Offline RKE2 binary and image archives verified against a trusted checksum manifest
- Passwordless administrative access or an equivalent configuration-management workflow
- A securely generated RKE2 token distributed outside Git

Use [Preparing air-gap artifacts](air-gap-artifacts.md) to download, verify, transfer and stage matching files. Configure the stable endpoint using [Load-balancer setup](load-balancer.md).

## Values used in the examples

The documentation-only address `198.51.100.10` represents the fixed load-balancer or VIP. Replace it everywhere. DNS is optional. If you use a DNS record, add it as an additional `--tls-san` on every server; do not add a made-up DNS name.

Each command section states where it runs. Never run all commands simultaneously across every server.

## 1. Prepare every node

Run from the cloned repository on each server and worker:

```bash
sudo install -m 0644 config/modules-load/rke2.conf /etc/modules-load.d/rke2.conf
sudo install -m 0644 config/sysctl/90-rke2.conf /etc/sysctl.d/90-rke2.conf
sudo modprobe overlay
sudo modprobe br_netfilter
sudo sysctl --system
```

Stage the verified RKE2 tarball and matching image archive at `/opt/rke2-offline-bundle/rke2/`. Deliver the join token outside Git, then create it safely:

```bash
sudo install -d -m 0700 /etc/rancher/rke2
sudo install -m 0600 /secure/source/rke2-token /etc/rancher/rke2/token
sudo ./scripts/preflight-check.sh
```

## 2. Bootstrap the first server

```bash
sudo ./scripts/generate-config.sh \
  --role init \
  --tls-san 198.51.100.10 \
  --output /etc/rancher/rke2/config.yaml

sudo ./scripts/install-server.sh --role init --config /etc/rancher/rke2/config.yaml
sudo ./scripts/install-server.sh --role init --config /etc/rancher/rke2/config.yaml --apply
sudo ./scripts/validate-cluster.sh
```

To use optional DNS, add `--tls-san rke2-api.example.com` to the generator command. To override the operating-system hostname, add `--node-name rke2-server-01`.

## 3. Join every additional server

Run the following on one new server at a time. Repeat it for any odd total number of servers, validating between nodes:

```bash
sudo ./scripts/generate-config.sh \
  --role join \
  --endpoint https://198.51.100.10:9345 \
  --tls-san 198.51.100.10 \
  --output /etc/rancher/rke2/config.yaml

sudo ./scripts/install-server.sh --role join --config /etc/rancher/rke2/config.yaml
sudo ./scripts/install-server.sh --role join --config /etc/rancher/rke2/config.yaml --apply
sudo ./scripts/validate-cluster.sh
```

## 4. Join any number of workers

Run on each worker:

```bash
sudo ./scripts/generate-config.sh \
  --role agent \
  --endpoint https://198.51.100.10:9345 \
  --output /etc/rancher/rke2/config.yaml

sudo ./scripts/install-agent.sh --config /etc/rancher/rke2/config.yaml
sudo ./scripts/install-agent.sh --config /etc/rancher/rke2/config.yaml --apply
```

From a server, verify all nodes:

```bash
sudo /var/lib/rancher/rke2/bin/kubectl \
  --kubeconfig /etc/rancher/rke2/rke2.yaml \
  get nodes -o wide
```

## Safety workflow

1. Keep critical server settings identical across all servers.
2. Run each installer once without `--apply` for its read-only validation.
3. Add only one server at a time and confirm etcd and node health.
4. Add workers in controlled batches and verify scheduling, networking and storage.

Never execute an example against production without peer review and an approved rollback plan.

## Common mistakes

| Mistake | Correct action |
|---|---|
| Running `init` on several nodes | Run it on the first server only |
| Using different critical options between servers | Keep cluster-wide settings identical |
| Adding DNS when no record exists | Omit the optional DNS SAN |
| Continuing after a failed validation | Stop, diagnose and restore health first |
| Joining all servers simultaneously | Join and validate one server at a time |
| Committing the token or kubeconfig | Deliver them through an approved secure channel |
| Mixing RKE2 artifact versions | Use matching binary, image and checksum files |
