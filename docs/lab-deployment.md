# Complete lab deployment

This walkthrough demonstrates the full sequence for three servers and two workers. Use only in a disposable non-production environment.

## Lab topology

The addresses are reserved for documentation and must be replaced in a real network.

| Node | Address | Role |
|---|---|---|
| Fixed endpoint | `198.51.100.10` | HAProxy/VIP |
| `rke2-server-01` | `192.0.2.11` | First server |
| `rke2-server-02` | `192.0.2.12` | Joining server |
| `rke2-server-03` | `192.0.2.13` | Joining server |
| `rke2-worker-01` | `192.0.2.21` | Worker |
| `rke2-worker-02` | `192.0.2.22` | Worker |

## Stage 1: prepare the fixed endpoint

Follow [Load-balancer setup](load-balancer.md). The `9345` and `6443` checks are expected to fail until the first server starts.

## Stage 2: prepare every node

Run on: all five RKE2 nodes  
Privilege: root  
Safe to repeat: yes

```bash
sudo install -m 0644 config/modules-load/rke2.conf /etc/modules-load.d/rke2.conf
sudo install -m 0644 config/sysctl/90-rke2.conf /etc/sysctl.d/90-rke2.conf
sudo modprobe overlay
sudo modprobe br_netfilter
sudo sysctl --system
```

Place matching, checksum-verified artifacts here:

```text
/opt/rke2-offline-bundle/rke2/rke2.linux-amd64.tar.gz
/opt/rke2-offline-bundle/rke2/rke2-images.linux-amd64.tar.zst
```

Deliver the same approved join token to every node without storing it in Git:

```bash
sudo install -d -m 0700 /etc/rancher/rke2
sudo install -m 0600 /secure/source/rke2-token /etc/rancher/rke2/token
sudo ./scripts/preflight-check.sh
```

Expected final line:

```text
All preflight checks passed
```

## Stage 3: install the first server

Run on: `rke2-server-01`

```bash
sudo ./scripts/setup-node.sh \
  --role init \
  --fixed-address 198.51.100.10 \
  --node-name rke2-server-01
```

Review the generated configuration. The wizard performs a dry run and prints the apply command. Run that command only after review.

Verify:

```bash
sudo systemctl is-active rke2-server
sudo ./scripts/validate-cluster.sh
```

Do not proceed until the server is healthy.

## Stage 4: join additional servers

Run first on `rke2-server-02`, validate it, and only then repeat on `rke2-server-03`:

```bash
sudo ./scripts/setup-node.sh \
  --role join \
  --fixed-address 198.51.100.10
```

The OS hostname is used because `--node-name` is omitted. Use a custom name only when necessary.

From an existing healthy server:

```bash
sudo /var/lib/rancher/rke2/bin/kubectl \
  --kubeconfig /etc/rancher/rke2/rke2.yaml \
  get nodes -o wide
```

Expected result: every installed server reports `Ready`.

## Stage 5: join workers

Run on each worker:

```bash
sudo ./scripts/setup-node.sh \
  --role agent \
  --fixed-address 198.51.100.10
```

Validate the agent locally:

```bash
sudo systemctl is-active rke2-agent
sudo journalctl -u rke2-agent -n 50 --no-pager
```

Then confirm from a server that the worker is `Ready`.

## Stage 6: workload smoke test

Run on a server:

```bash
sudo /var/lib/rancher/rke2/bin/kubectl \
  --kubeconfig /etc/rancher/rke2/rke2.yaml \
  create deployment hello-rke2 --image=nginx:alpine

sudo /var/lib/rancher/rke2/bin/kubectl \
  --kubeconfig /etc/rancher/rke2/rke2.yaml \
  rollout status deployment/hello-rke2 --timeout=120s
```

In a true air-gapped environment, the test image must already exist in the approved image source. Delete the test when finished:

```bash
sudo /var/lib/rancher/rke2/bin/kubectl \
  --kubeconfig /etc/rancher/rke2/rke2.yaml \
  delete deployment hello-rke2
```

## Stage 7: record evidence

Record, without copying secrets:

- RKE2 version and artifact checksum result
- Node names, roles and readiness
- Load-balancer checks
- Cluster validation result
- Snapshot creation and off-node copy result
- Any deviations from the reviewed design

## Failure rule

If a stage fails, stop at that stage. Do not add more nodes until the cause is understood and the cluster returns to a healthy state.
