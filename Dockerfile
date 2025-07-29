# syntax=docker/dockerfile:1

# Use phusion/passenger-full as base image for a smaller image.
FROM phusion/passenger-ruby34:latest

# Install jemalloc for improved memory management
RUN apt-get update && apt-get install -y libjemalloc2 \
    && rm -rf /var/lib/apt/lists/*

# Set optimization and security flags
ENV CFLAGS="-O3 -fno-fast-math -fstack-protector-strong -D_FORTIFY_SOURCE=2 -Wall -Wextra -fPIC -Wformat -Wformat-security"
ENV CXXFLAGS="-O3 -fno-fast-math -fstack-protector-strong -D_FORTIFY_SOURCE=2 -Wall -Wextra -fPIC -Wformat -Wformat-security"
ENV LDFLAGS="-Wl,-z,relro -Wl,-z,now"
ENV RUBYOPT="--yjit --yjit-exec-mem-size=200 --yjit-mem-size=256 --yjit-call-threshold=20"

# Preload jemalloc for all processes (Ruby, Passenger, Nginx, etc.)
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

# Set correct environment variables.
ENV HOME /root

# Enable Nginx and Passenger
RUN rm -f /etc/service/nginx/down

# Set working directory for app
WORKDIR /home/app/webapp

# Copy Gemfile and Gemfile.lock first for efficient caching
COPY Gemfile Gemfile.lock ./

# Install Ruby gems using RVM's default Ruby (3.4.2)
RUN bash -lc 'rvm --default use ruby-3.4.2 && bundle install --jobs 4 --retry 3'

# Copy package.json and bun.lock for JS dependencies
COPY package.json bun.lock ./

# Install unzip for Bun installation
RUN apt-get update && apt-get install -y unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Bun (for JS package management and build only)
ENV BUN_INSTALL=/usr/local/bun
ENV PATH=/usr/local/bun/bin:$PATH
RUN curl -fsSL https://bun.sh/install | bash -s -- "bun-v1.2.5"
RUN bun install --frozen-lockfile

# Copy the rest of the application code
COPY . .

# Ensure correct ownership for the app user
RUN chown -R app:app /home/app/webapp

# Precompile Rails bootsnap cache
RUN bash -lc 'rvm --default use ruby-3.4.2 && bundle exec bootsnap precompile app/ lib/'

# Precompile assets with vite (using bun)
RUN SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production VITE_RUBY_MODE=production \
    bun run build \
    && rm -rf public/vite-dev public/vite-test

# Remove default Nginx site and add custom config for Rails app
RUN rm /etc/nginx/sites-enabled/default
COPY docker/webapp.conf /etc/nginx/sites-enabled/webapp.conf

# Create runit service for Solid Queue worker process
RUN mkdir -p /etc/service/worker
COPY docker/worker.sh /etc/service/worker/run

# Clean up APT when done
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Use baseimage-docker's init process
CMD ["/sbin/my_init"]
