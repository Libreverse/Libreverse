# Passenger + Nginx tuning applied in this repo

This app ships a containerized Nginx + Passenger configuration. We applied a subset of the provided Linux tuning list that is safe and effective inside the container. Host-level kernel/sysctl tuning is intentionally documented but not enforced from the container.

## What we applied

- Nginx
    - `worker_processes auto;` and `worker_connections 1024` (already present)
    - Gzip disabled here (zstd middleware already handles compression in-app)
    - `aio threads;` to offload disk reads
    - `listen ... reuseport;` in the app server for better connection distribution
    - access log buffering (`buffer=16k`)
    - Included `/etc/nginx/conf.d/*.conf` to allow runtime tuning drops
- Passenger
    - `passenger_app_env production;` in the virtual host
    - `passenger_pre_start` is generated at boot. It must point to a URL that matches `server_name` and port. Override with `PASSENGER_PRESTART_URL` or its parts (scheme/host/port/path).
    - At container start, we compute process pool size from the existing `ThreadBudget` (see `config/thread_budget.rb`) and write `/etc/nginx/conf.d/99-passenger-pool.conf` with:
        - `passenger_max_pool_size`
        - `passenger_min_instances`
        - `passenger_max_instances_per_app`
    - This aligns pool size to app thread budget when running Passenger OSS (1 concurrent request per process). If you use Passenger Enterprise, you can extend the entrypoint to also set `passenger_concurrency_model thread;` and map `ThreadBudget.app_threads` to `passenger_thread_count` with fewer processes.

## What we did not apply (host-level or situational)

- Kernel `sysctl` changes (e.g., `net.ipv4.tcp_tw_reuse`, conntrack sizes): must be set on the host. See below for suggested values.
- TLS cipher list and ECC keys: enable when binding 443; current image leaves certs commented.
- Logging to syslog: not enabled by default; use volume mounts or sidecars.
- `proxy_buffering`/streaming toggles: defaults left intact; adjust per endpoint if you deploy streaming.

## Host-level suggestions (non-container)

- `/etc/sysctl.conf` (or drop-ins):
    - `net.ipv4.tcp_tw_reuse = 1`
    - `net.netfilter.nf_conntrack_max = 65536` (name varies by distro)
    - Apply via `sysctl -p`
- Nginx TLS (when terminating TLS here):
    - `ssl_protocols TLSv1.2 TLSv1.3;`
    - Modern AEAD ciphers; consider ECDSA cert alongside RSA
- Load testing & verification: use `passenger-status`, `passenger-memory-stats`, Siege, or k6.

## Notes

- The thread/process budgeting centralizes in `config/thread_budget.rb`. We export `RAILS_MAX_THREADS` and database pool sizing reads `APP_THREADS_BUDGET` via ERB in `config/database.yml`.
- The container entrypoint creates `/etc/nginx/conf.d/99-passenger-pool.conf` on every start; if you override budgets via env, the pool sizing adapts accordingly.
