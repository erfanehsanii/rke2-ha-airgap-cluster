# Configuration reference

This page explains the settings included in this repository. It is not a list of every RKE2 option.

## Classification

| Label | Meaning |
|---|---|
| Required | Installation cannot work correctly without the value in this design |
| Recommended | Strong operational or security default used by this project |
| Optional | Enable only when the capability is needed |
| Advanced | Requires design review and additional validation |
| Must match | Use the same value on every RKE2 server |

## Included RKE2 settings

| Parameter | Classification | Applies to | Explanation |
|---|---|---|---|
| `server` | Required for `join` and `agent`; forbidden for `init` | Joining servers and workers | Registration URL such as `https://198.51.100.10:9345` |
| `token-file` | Required | All nodes | Reads the join token from a protected file rather than storing it in YAML |
| `node-name` | Optional | All nodes | Overrides the OS hostname. Omit it when the hostname is already correct and unique |
| `tls-san` | Required for the fixed endpoint | Servers | Adds the VIP, load-balancer address or DNS name to the API certificate |
| `cni` | Optional explicit default; must match | Servers | Selects Canal. Do not change CNI on one server only |
| `write-kubeconfig-mode` | Recommended | Servers | Keeps the generated administrator kubeconfig readable only by root |
| `etcd-expose-metrics` | Optional, security-sensitive | Servers | Exposes etcd metrics. Restrict network access to trusted monitoring systems |
| `kube-apiserver-arg` | Optional | Servers | Enables API audit-log rotation settings used by this example |
| `kube-controller-manager-arg` | Optional, security-sensitive | Servers | Exposes metrics on all interfaces; protect the port at the network layer |
| `kube-scheduler-arg` | Optional, security-sensitive | Servers | Exposes scheduler metrics on all interfaces; protect the port |
| `kubelet-arg` | Optional | All nodes | Controls container-log rotation |
| `kube-proxy-arg` | Optional, security-sensitive | All nodes | Exposes kube-proxy metrics on `10249`; restrict access |

## Optional DNS

DNS is not required when a stable IP or VIP is available.

IP only:

```yaml
tls-san:
  - 198.51.100.10
```

IP and DNS:

```yaml
tls-san:
  - 198.51.100.10
  - rke2-api.example.com
```

Use the same SAN list on all servers. Workers do not need this block.

## Settings that require extra care

RKE2 validates critical settings when another server joins. Network CIDRs, cluster DNS/domain, CNI choices and other critical cluster-wide settings must be consistent. A mismatch can prevent a server from joining.

Do not casually change these after cluster creation:

- Pod and service CIDRs
- Cluster DNS IP or cluster domain
- CNI provider
- Cloud-controller and kube-proxy behavior
- Datastore selection
- Encryption or compliance profiles

Review the current official RKE2 server configuration reference before adding advanced parameters.

## Node-specific settings

These may legitimately differ by node:

- `node-name`
- `node-ip`
- Node labels and taints
- Provider-specific node metadata

Node labels and taints applied only during registration may not be reconciled automatically later. Manage ongoing placement changes using Kubernetes operations and documented change control.

## Configuration precedence

This repository uses `/etc/rancher/rke2/config.yaml`. Avoid mixing configuration files, environment variables and systemd arguments unless you understand RKE2 precedence. A single reviewed file is easier for junior operators to audit.

## Secret handling

The following must never be committed:

- `/etc/rancher/rke2/token`
- `/etc/rancher/rke2/rke2.yaml`
- `/var/lib/rancher/rke2/server/node-token`
- Certificates and private keys
- `registries.yaml` when it contains credentials
- etcd snapshots

Use `0600` permissions for token and kubeconfig files and deliver them through an approved secret-management channel.
