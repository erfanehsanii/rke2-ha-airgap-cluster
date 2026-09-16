# Load-balancer setup

RKE2 HA needs a stable registration address in front of all server nodes. This guide uses HAProxy in TCP mode. DNS is optional; a VIP or fixed IP is enough.

## Example topology

All addresses below are reserved for documentation.

| Purpose | Address |
|---|---|
| Fixed endpoint | `198.51.100.10` |
| Server 1 | `192.0.2.11` |
| Server 2 | `192.0.2.12` |
| Server 3 | `192.0.2.13` |

## Generate a configuration for any server count

The generator creates both required backends from one server list:

```bash
sudo ./scripts/generate-haproxy-config.sh \
  --bind-address 198.51.100.10 \
  --server rke2-server-01=192.0.2.11 \
  --server rke2-server-02=192.0.2.12 \
  --server rke2-server-03=192.0.2.13 \
  --output /etc/haproxy/haproxy.cfg
```

Add or remove `--server NAME=ADDRESS` arguments for your server count. Do not add workers. The script refuses to overwrite an existing file unless `--force` is supplied.

For manual configuration, copy [the HAProxy example](../examples/load-balancer/haproxy.example.cfg), replace every placeholder and keep the same server list in both backends. The backend pattern is:

```haproxy
server rke2-server-01 192.0.2.11:6443 check
server rke2-server-02 192.0.2.12:6443 check
server rke2-server-03 192.0.2.13:6443 check
```

Repeat the same server list in the `9345` backend.

## Validate before reload

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
```

Expected result includes:

```text
Configuration file is valid
```

If validation fails, do not reload HAProxy.

## Apply safely

```bash
sudo systemctl reload haproxy
sudo systemctl is-active haproxy
sudo journalctl -u haproxy -n 50 --no-pager
```

Expected service state:

```text
active
```

## Connectivity checks

Before the first RKE2 server starts, a TCP connection through the load balancer can fail because no backend is listening yet. After the first server is healthy, test from another node:

```bash
nc -vz 198.51.100.10 9345
nc -vz 198.51.100.10 6443
```

Expected result includes `succeeded` or `open` for both ports.

## Production considerations

- A single HAProxy host is still a single point of failure.
- For load-balancer HA, use at least two load balancers with a managed VIP or an approved failover mechanism.
- Restrict `6443` and `9345` to intended networks.
- Preserve the client source information required by your logging and security design.
- Monitor listener state, backend health and configuration reload failures.
- Validate that the endpoint is included in every server certificate SAN.

## Common mistakes

| Mistake | Result |
|---|---|
| Sending traffic to workers | Registration or API traffic fails |
| Configuring only `6443` | New nodes cannot register through `9345` |
| Configuring only `9345` | Kubernetes API clients cannot use the endpoint |
| Forgetting the endpoint SAN | TLS certificate validation fails |
| Reloading invalid HAProxy configuration | Service interruption or rejected reload |
| Assuming one HAProxy instance provides full HA | Load balancer remains a single point of failure |
