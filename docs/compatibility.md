# Tested versions and compatibility

This repository is a reusable reference, not a promise that every future RKE2 release behaves identically.

## Evidence from the sanitized source environment

| Component | Observed or targeted value | Validation level |
|---|---|---|
| RKE2 | `v1.35.5+rke2r2` | Configuration derived from the reviewed environment |
| Kubernetes | Bundled with the RKE2 release | Cluster discovery evidence reviewed |
| CPU architecture | `amd64` | Installer currently expects amd64 artifact names |
| Operating system | systemd-based Linux | Scripts check systemd and required kernel modules |
| CNI | Canal | Configuration examples and validation paths included |
| Datastore | Embedded etcd | HA, snapshot and restore procedures included |

## Before using another version

1. Check the official RKE2 support matrix and release notes.
2. Download the binary and image archives for the same version and architecture.
3. Verify checksums using a trusted source.
4. Confirm CNI and ingress defaults for the chosen release.
5. Run repository tests and a non-production installation.
6. Test backup and restore before production approval.

## Architecture limitation

The provided installers currently use these amd64 filenames:

```text
rke2.linux-amd64.tar.gz
rke2-images.linux-amd64.tar.zst
```

Using arm64 requires reviewed changes to artifact names and corresponding validation. Do not rename incompatible artifacts merely to satisfy the script.

## Operating-system note

The scripts rely on Bash, systemd, GNU userland commands, kernel modules and sysctl behavior. Package installation, SELinux policy preparation, firewall management and persistent network configuration vary by distribution and remain operator responsibilities.
