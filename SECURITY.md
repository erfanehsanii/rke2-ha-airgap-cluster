# Security Policy

Never commit live tokens, kubeconfigs, registry authentication, certificates, private keys, snapshots, environment files, internal addresses, or production inventory.

Use a secure secret-distribution system to place the RKE2 token at the path referenced by `token-file`. Restrict the token and generated kubeconfig to `0600`. Treat etcd snapshots as sensitive because they can contain Kubernetes Secret objects.

Before every commit, run:

```bash
./scripts/security-scan.sh
```

If a secret enters Git history, rotating the secret and rewriting the affected history are both required. Adding the file to `.gitignore` is not sufficient.

Report security issues privately to the repository owner. Do not open a public issue containing sensitive evidence.
