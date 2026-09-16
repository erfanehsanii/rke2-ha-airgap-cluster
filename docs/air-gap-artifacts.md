# Preparing air-gap artifacts

Perform downloads only on an approved internet-connected staging system. Transfer verified artifacts into the offline environment using the organization's approved process.

## 1. Select one version and architecture

The binary and image archives must use the same RKE2 release and CPU architecture. This example uses amd64:

```bash
export RKE2_VERSION='v1.35.5+rke2r2'
export RKE2_ARCH='amd64'
export RKE2_STAGING_DIR="$PWD/rke2-artifacts-${RKE2_VERSION}"
mkdir -p "$RKE2_STAGING_DIR"
cd "$RKE2_STAGING_DIR"
```

Review the selected release against the current RKE2 support matrix before continuing.

## 2. Download artifacts on the connected system

```bash
RKE2_URL_TAG=${RKE2_VERSION//+/%2B}
RKE2_RELEASE_URL="https://github.com/rancher/rke2/releases/download/${RKE2_URL_TAG}"

curl --fail --location --remote-name \
  "${RKE2_RELEASE_URL}/rke2.linux-${RKE2_ARCH}.tar.gz"
curl --fail --location --remote-name \
  "${RKE2_RELEASE_URL}/rke2-images.linux-${RKE2_ARCH}.tar.zst"
curl --fail --location --remote-name \
  "${RKE2_RELEASE_URL}/sha256sum-${RKE2_ARCH}.txt"
```

Do not replace a failed download with an artifact from an untrusted mirror.

## 3. Verify checksums

```bash
sha256sum --ignore-missing --check "sha256sum-${RKE2_ARCH}.txt"
```

Expected output must report `OK` for both downloaded archives. Stop if verification fails.

## 4. Create a transfer manifest

```bash
sha256sum \
  "rke2.linux-${RKE2_ARCH}.tar.gz" \
  "rke2-images.linux-${RKE2_ARCH}.tar.zst" \
  > TRANSFER-SHA256SUMS
```

Transfer the two archives and `TRANSFER-SHA256SUMS`. Do not include credentials, kubeconfigs or tokens in the artifact bundle.

## 5. Verify again on every offline node

```bash
cd /secure/transfer/location
sha256sum --check TRANSFER-SHA256SUMS
```

Then stage the files where this repository expects them:

```bash
sudo install -d -m 0755 /opt/rke2-offline-bundle/rke2
sudo install -m 0644 rke2.linux-amd64.tar.gz /opt/rke2-offline-bundle/rke2/
sudo install -m 0644 rke2-images.linux-amd64.tar.zst /opt/rke2-offline-bundle/rke2/
```

Run `sudo ./scripts/preflight-check.sh` only after artifacts and the protected token file are present.

## Important limitations

- The repository installers currently expect amd64 filenames.
- Additional CNI or cloud-provider images may be required when the design differs from Canal on bare metal.
- Artifact verification proves file integrity relative to the manifest; it does not prove operational compatibility.
- Keep evidence of the selected version, source and checksum result.
