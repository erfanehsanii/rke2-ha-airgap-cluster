# Quick start

## Prerequisites

- Supported 64-bit Linux hosts using systemd
- An odd number of server nodes; three is recommended for HA
- Zero or more workers
- A stable TCP load-balancer endpoint for ports `6443` and `9345`
- Offline RKE2 binary and image archives verified against a trusted checksum manifest
- Passwordless administrative access or an equivalent configuration-management workflow
- A securely generated RKE2 token distributed outside Git

## Values used in the examples

The documentation-only address `198.51.100.10` represents the fixed load-balancer or VIP. Replace it everywhere. DNS is optional. If you use a DNS record, add it as an additional `--tls-san` on every server; do not add a made-up DNS name.

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
