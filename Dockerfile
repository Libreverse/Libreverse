# syntax=docker/dockerfile:1

# Use phusion/passenger-full as base image for a smaller image.
FROM phusion/passenger-ruby34:latest

# Install jemalloc for improved memory management (with dev headers for optimization)
# Also install and configure ModSecurity (with OWASP CRS) for WAF protection
RUN set -eux; \
        rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock || true; \
        apt-get update; \
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
            libjemalloc2 libjemalloc-dev \
            libmodsecurity3 libnginx-mod-http-modsecurity modsecurity-crs \
            shared-mime-info coreutils imagemagick unzip \
        ; \
        mkdir -p /etc/modsecurity; \
        ln -sf /usr/share/modsecurity-crs/rules /etc/modsecurity/rules || true; \
        (ln -sf /usr/share/nginx/modules-available/mod-http-modsecurity.conf /etc/nginx/modules-enabled/50-mod-http-modsecurity.conf || true); \
        rm -rf /var/lib/apt/lists/*

# Provide consolidated main include for ModSecurity rules (copied later before Nginx reload)
COPY docker/modsecurity/modsecurity.conf /etc/modsecurity/modsecurity.conf
COPY docker/modsecurity-main.conf /etc/modsecurity/main.conf
COPY docker/modsecurity-overrides_pre.conf /etc/modsecurity/overrides_pre.conf
COPY docker/modsecurity-overrides.conf /etc/modsecurity/overrides.conf
# Use the CRS setup template to ensure tx.crs_setup_version is set
# Try common package locations, fall back to upstream if missing
RUN set -eux; \
        if [ -f /usr/share/modsecurity-crs/crs-setup.conf.example ]; then \
            cp /usr/share/modsecurity-crs/crs-setup.conf.example /etc/modsecurity/crs-setup.conf; \
        elif [ -f /usr/share/doc/modsecurity-crs/examples/crs-setup.conf.example.gz ]; then \
            zcat /usr/share/doc/modsecurity-crs/examples/crs-setup.conf.example.gz > /etc/modsecurity/crs-setup.conf; \
        elif [ -f /usr/share/doc/modsecurity-crs/examples/crs-setup.conf.example ]; then \
            cp /usr/share/doc/modsecurity-crs/examples/crs-setup.conf.example /etc/modsecurity/crs-setup.conf; \
        else \
            curl -fsSL https://raw.githubusercontent.com/coreruleset/coreruleset/v3.3.5/crs-setup.conf.example -o /etc/modsecurity/crs-setup.conf; \
        fi
# Fetch full upstream unicode.mapping (rather than storing a local stub)
RUN curl -fsSL https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/unicode.mapping -o /etc/modsecurity/unicode.mapping

# Set optimization and security flags
ENV CFLAGS="-O3 -fno-fast-math -fstack-protector-strong -D_FORTIFY_SOURCE=2 -Wall -Wextra -fPIC -Wformat -Wformat-security"
ENV CXXFLAGS="-O3 -fno-fast-math -fstack-protector-strong -D_FORTIFY_SOURCE=2 -Wall -Wextra -fPIC -Wformat -Wformat-security"
ENV LDFLAGS="-Wl,-z,relro -Wl,-z,now"
ENV RUBYOPT="--yjit --yjit-exec-mem-size=200 --yjit-mem-size=256 --yjit-call-threshold=20 --yjit-disable"

# Set correct environment variables.
ENV HOME=/root

# Enable Nginx and Passenger
RUN rm -f /etc/service/nginx/down

# Set working directory for app
WORKDIR /home/app/webapp

# Copy Gemfile and Gemfile.lock first for efficient caching
COPY Gemfile Gemfile.lock ./

# Install production gems (exclude development & test groups)
RUN bash -lc 'rvm --default use ruby-3.4.2 && bundle config set without "development test" && bundle install --jobs=$(nproc) --retry 3'

# Copy package.json and bun.lock for JS dependencies
COPY package.json bun.lock ./

# Install Bun (for JS package management and build only)
ENV BUN_INSTALL=/usr/local/bun
ENV PATH=/usr/local/bun/bin:$PATH
RUN curl -fsSL https://bun.sh/install | bash -s -- "bun-v1.2.5"

# Copy the rest of the application code (including vendor/)
COPY . .

# Ensure correct ownership for the app user (before bun install, so node_modules is not affected)
RUN chown -R app:app /home/app/webapp

# Now install JS dependencies (vendor/javascript/p2p should exist)
RUN bun install --frozen-lockfile

# Precompile Rails bootsnap cache
RUN bash -lc 'rvm --default use ruby-3.4.2 && bundle exec bootsnap precompile app/ lib/'

# Precompile assets with vite (using bun)
RUN SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production VITE_RUBY_MODE=production \
    bun run build \
    && rm -rf public/vite-dev public/vite-test

# Remove default Nginx site and add custom config for Rails app
RUN rm /etc/nginx/sites-enabled/default
COPY docker/webapp.conf /etc/nginx/sites-enabled/webapp.conf
COPY docker/nginx-main.conf /etc/nginx/nginx.conf
COPY docker/passenger.conf /etc/nginx/passenger.conf

# Create runit service for Solid Queue worker process
RUN mkdir -p /etc/service/worker
COPY docker/worker.sh /etc/service/worker/run
RUN chmod +x /etc/service/worker/run

# Clean up APT when done
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add entrypoint script to launch app with jemalloc only for Passenger
COPY docker/entrypoint-with-jemalloc.sh /usr/local/bin/entrypoint-with-jemalloc.sh
RUN chmod +x /usr/local/bin/entrypoint-with-jemalloc.sh

# Use baseimage-docker's init process, but override to use jemalloc for app
CMD ["/usr/local/bin/entrypoint-with-jemalloc.sh"]
