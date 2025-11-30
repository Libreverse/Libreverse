
# Nginx Production Configuration (Meticulous Reference)

This page provides a comprehensive, line-by-line reference for every Nginx setting used in production for Libreverse. Each directive is explained with its value, purpose, and operational/security notes. Config files are located in [`docker/`](../docker/).

---

## Table of Contents

- [nginx-main.conf](#nginx-mainconf)
- [nginx-libreverse.conf](#nginx-libreverseconf)
- [webapp.conf](#webappconf)
- [passenger.conf](#passengerconf)
- [Security and Best Practices](#security-and-best-practices)
- [File Locations](#file-locations)
- [See Also](#see-also)

---

## nginx-main.conf

**Location:** [`docker/nginx-main.conf`](../docker/nginx-main.conf)

### Top-level (main context)

- `include /etc/nginx/modules-enabled/*.conf;`
  - Loads all available Nginx modules. Ensures required modules (e.g., Lua, Passenger, ModSecurity) are available.

- `include /etc/nginx/main.d/*.conf;`
  - Allows drop-in configuration files for environment-specific or runtime settings.

- `user www-data;`
  - Runs Nginx worker processes as the `www-data` user for security.

- `include /etc/nginx/worker_processes.conf;`
  - Worker process count is set dynamically at container startup to match the thread budget between Passenger and Nginx.

- `worker_rlimit_nofile 40000;`
  - Raises the maximum number of open files per worker to 40,000. Prevents file descriptor exhaustion under high load.

- `worker_priority -5;`
  - Increases Nginx worker process priority for better CPU scheduling.

- `pid /run/nginx.pid;`
  - Location of the Nginx process ID file.

### events block

- `worker_connections 8096;`
  - Maximum simultaneous connections per worker process.

- `accept_mutex on;`
  - Enables accept mutex to serialize accept() calls, reducing connection thrashing.

- `multi_accept on;`
  - Allows workers to accept multiple new connections at once for efficiency.

- `use epoll;`
  - Uses the epoll event method (Linux only) for high performance.

### http block

- `client_max_body_size 2g;`
  - Allows uploads up to 2GB. Required for large file support.

- `client_body_buffer_size 16k;`
  - Buffer size for request bodies in memory. Larger bodies spill to disk.

- `client_header_buffer_size 4k;`
  - Buffer size for request headers.

- `large_client_header_buffers 4 8k;`
  - Up to 4 large headers, each up to 8k, for requests with big cookies/headers.

- `client_body_temp_path /home/app/webapp/tmp/nginx_body 2 2;`
  - Path for temporary files for large request bodies. Uses 2-level subdirectory structure for scalability.

- `aio threads;`
  - Enables asynchronous I/O using threads for disk operations.

- `sendfile on;`
  - Enables zero-copy file transmission for static files.

- `tcp_nopush on;`
  - Optimizes packet transmission for sendfile.

- `tcp_nodelay on;`
  - Sends packets immediately for low-latency connections.

- `keepalive_timeout 15;`
  - Idle keepalive connections are closed after 15 seconds.

- `keepalive_requests 100;`
  - Maximum 100 requests per keepalive connection.

- `client_body_timeout 12s;`
  - Closes connection if client takes longer than 12s to send body.

- `client_header_timeout 12s;`
  - Closes connection if client takes longer than 12s to send headers.

- `send_timeout 10s;`
  - Closes connection if Nginx takes longer than 10s to send response.

- `log_format libreverse_main ...`
  - Custom log format for unified, parseable logs. Includes remote address, user, time, request, status, bytes sent, referer, user agent, and request time.

- `access_log /dev/stdout libreverse_main buffer=16k;`
  - Logs access requests to container stdout using the custom format. Buffered for performance.

- `error_log /dev/stderr warn;`
  - Logs errors to container stderr at warning level or higher.

- `open_file_cache max=2000 inactive=20s;`
  - Caches up to 2000 open file descriptors for 20s after last use.

- `open_file_cache_valid 60s;`
  - File cache is validated every 60s.

- `open_file_cache_min_uses 5;`
  - Only cache files accessed at least 5 times.

- `proxy_buffer_size 128k;`
  - Buffer size for proxied responses (useful if proxying, harmless otherwise).

- `proxy_buffers 100 128k;`
  - Up to 100 proxy buffers of 128k each.

- `gzip off;`
  - Disables gzip compression at Nginx. Compression is handled by the Rails app to avoid double-compression.

- `init_by_lua_block { ... }`
  - Initializes CrowdSec Lua module for security. Ensures Lua path is set and CrowdSec is initialized with config.

- `init_worker_by_lua_block { ... }`
  - Per-worker initialization for CrowdSec. Sets up stream mode and metrics for worker 0.

- `include /etc/nginx/passenger.conf;`
  - Loads Passenger-specific configuration.

- `include /etc/nginx/conf.d/*.conf;`
  - Loads runtime-generated tuning files.

- `include /etc/nginx/mime.types;`
  - Loads MIME type mappings for file extensions.

- `default_type application/octet-stream;`
  - Default MIME type for files with unknown extension.

- `include /etc/nginx/sites-enabled/*;`
  - Loads all site/server block configurations.

---

## nginx-libreverse.conf

**Location:** [`docker/nginx-libreverse.conf`](../docker/nginx-libreverse.conf)

- `client_max_body_size 2g;`
  - Ensures large uploads are supported (overrides any lower default).

- `log_format libreverse_main ...`
  - Defines the custom log format if not already present.

- `access_log /dev/stdout libreverse_main buffer=16k;`
  - Ensures access logs use the custom format and are sent to stdout.

- `include /etc/nginx/passenger.conf;`
  - Loads Passenger tuning if present.

*Notes:*

  - This file is loaded after the main config to avoid duplicate directives.
  - CrowdSec and site configs are not re-included here to prevent conflicts.

---

## webapp.conf

**Location:** [`docker/webapp.conf`](../docker/webapp.conf)

### server block

- `listen 3000 default_server reuseport backlog=8192;`
  - Listens on port 3000 for HTTP/1.1. `reuseport` allows multiple workers to bind the same port. `backlog=8192` sets the connection queue size.
  - (TLS/HTTP2/QUIC listen directives are present but commented out; enable for HTTPS.)

- `server_name libreverse;`
  - Server name for virtual hosting.

- `root /home/app/webapp/public;`
  - Document root for static files.

#### TLS Configuration (commented)

- `ssl_certificate`, `ssl_certificate_key`, `ssl_protocols`, etc.
  - Present but commented out. Enable and configure for HTTPS in production.

#### ModSecurity

- `modsecurity on;`
  - Enables ModSecurity WAF for this server block.

- `modsecurity_rules_file /etc/modsecurity/main.conf;`
  - Loads the main ModSecurity ruleset (typically OWASP CRS).

#### Passenger

- `passenger_enabled on;`
  - Enables Passenger application server for this server block.

- `passenger_user app;`
  - Runs the app as the `app` user.

- `passenger_app_env production;`
  - Sets Rails environment to production.

- `passenger_min_instances 1;`
  - Keeps at least one app process resident to reduce cold starts.

- `reset_timedout_connection on;`
  - Proactively resets timed out client connections to free sockets.

- `passenger_env_var X-Accel-Mapping ...`
  - Sets X-Accel-Redirect mappings for internal file serving. Maps public paths to internal Nginx locations for efficient file delivery.

#### CrowdSec

- `access_by_lua_block { ... }`
  - Invokes CrowdSec Lua bouncer to check and allow/block requests based on IP reputation.

#### Action Cable

- `location /cable { ... }`
  - Dedicated settings for Action Cable (WebSockets). Forces unlimited concurrent requests per process.

#### Internal File Serving

- `location ^~ /_internal/storage/ { internal; alias /home/app/webapp/storage/; }`
  - Internal-only location for X-Accel-Redirect. Not accessible directly by clients.

- `location ^~ /_internal/private/ { internal; alias /home/app/webapp/private/; }`
  - Internal-only location for private files.

#### Static Assets

- `location ~* \.(?:css|js|mjs|json|jpg|jpeg|gif|png|svg|webp|ico|woff2?|ttf|otf|map)$ { ... }`
  - Caches static assets for 30 days. Sets `Cache-Control: public, max-age=31536000`. Uses `try_files $uri =404` for fallback.

#### Upload/Download Tuning

- `client_body_timeout 60s;`
  - Allows slow clients up to 60s to send request bodies.

- `send_timeout 60s;`
  - Allows up to 60s to send responses to clients.

- `directio 4m;`
  - Enables direct I/O for files larger than 4MB (useful for large uploads/downloads).

- `sendfile_max_chunk 512k;`
  - Limits sendfile to 512k chunks for smoother large file delivery.

#### Nginx Status

- `location = /nginx_status { stub_status; allow 127.0.0.1; deny all; }`
  - Exposes Nginx status metrics on localhost only for troubleshooting.

#### gRPC Proxy

- `location /api/grpc { ... }`
  - Proxies gRPC requests to a local gRPC server on port 50051. ModSecurity is disabled for this location. Sets gRPC-specific headers and timeouts.

---

## passenger.conf

**Location:** [`docker/passenger.conf`](../docker/passenger.conf)

- `passenger_temp_path /home/app/webapp/tmp/passenger;`
  - Sets the temp directory for Passenger's disk-backed buffering.

- `passenger_buffer_upload on;`
  - Enables disk-backed buffering for uploads to reduce memory usage.

- `passenger_response_buffer_high_watermark 268435456;`
  - Sets the high watermark for response buffering to 256MB. Slow clients won't block app processes.

- `passenger_start_timeout 120;`
  - Increases the startup timeout for app preloader to 120s (useful for slow DB or asset init).

*Notes:*

  - No explicit pool caps; scaling is managed by Passenger defaults/environment.
  - `passenger_pre_start` is generated at startup from the environment.

---

## Security and Best Practices

- **CrowdSec:** Integrated at both HTTP and worker levels for real-time blocking and metrics.
- **ModSecurity:** Enabled with OWASP CRS for WAF protection.
- **Unified Logging:** All logs are sent to container stdout/stderr for aggregation.
- **No Duplicate Directives:** Configs are split to avoid conflicts and allow runtime overrides.
- **TLS:** TLS/SSL settings are present but commented; enable and configure for production HTTPS.

---

## File Locations

- All referenced config files are in the [`docker/`](../docker/) directory.
- Site configs are included via `/etc/nginx/sites-enabled/*`.

---

## See Also

- [Enhanced Caching](enhanced-caching.md)
- [Maximum Compression Implementation](maximum-compression-implementation.md)
- [Rate Limiting Implementation](rate-limiting-implementation.md)
- [Logging](logging.md)

---

For further details, see the comments in each config file or contact the DevOps team.
