# syntax=docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.4.1
FROM quay.io/evl.ms/fullstaq-ruby:${RUBY_VERSION}-jemalloc-slim AS base

ENV CFLAGS="-O3 -fno-fast-math -fstack-protector-strong -D_FORTIFY_SOURCE=2 -Wall -Wextra -fPIC -Wformat -Wformat-security"
ENV CXXFLAGS="-O3 -fno-fast-math -fstack-protector-strong -D_FORTIFY_SOURCE=2 -Wall -Wextra -fPIC -Wformat -Wformat-security"
ENV LDFLAGS="-Wl,-z,relro -Wl,-z,now"

# Rails app lives here
WORKDIR /rails

# Update gems and bundler
RUN gem update --system --no-document \
    && gem install -N bundler

# Install base packages including nginx
RUN --mount=type=cache,id=dev-apt-cache,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,id=dev-apt-lib,sharing=locked,target=/var/lib/apt \
    apt-get update -qq \
    && apt-get install --no-install-recommends -y \
        curl \
        sqlite3 \
        dirmngr \
        gnupg \
        ca-certificates \
        libssl-dev \
        procps \
    && rm -rf /var/lib/apt/lists/*

# Set production environment
ENV BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    RAILS_ENV="production"

# Throw-away build stages to reduce size of final image
FROM base AS prebuild

# Install packages needed to build gems and Passenger
RUN --mount=type=cache,id=dev-apt-cache,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,id=dev-apt-lib,sharing=locked,target=/var/lib/apt \
    apt-get update -qq \
    && apt-get install --no-install-recommends -y \
        build-essential \
        libffi-dev \
        libyaml-dev \
        pkg-config \
        unzip \
        libssl-dev \
    && rm -rf /var/lib/apt/lists/*

FROM prebuild AS bun

# Install Bun
ARG BUN_VERSION=1.2.5
ENV BUN_INSTALL=/usr/local/bun
ENV PATH=/usr/local/bun/bin:$PATH
RUN curl -fsSL https://bun.sh/install | bash -s -- "bun-v${BUN_VERSION}"

# Install node modules
COPY package.json bun.lock ./
RUN --mount=type=cache,id=bld-bun-cache,target=/root/.bun \
    bun install --frozen-lockfile

FROM prebuild AS build

# Install application gems (including passenger)
COPY Gemfile Gemfile.lock ./
RUN --mount=type=cache,id=bld-gem-cache,sharing=locked,target=/srv/vendor \
    bundle config set app_config .bundle \
    && bundle config set path /srv/vendor \
    && bundle install \
    && bundle exec bootsnap precompile --gemfile \
    && bundle clean \
    && mkdir -p vendor \
    && bundle config set path vendor \
    && cp -ar /srv/vendor .

# Copy bun modules
COPY --from=bun /rails/node_modules /rails/node_modules
COPY --from=bun /usr/local/bun /usr/local/bun
ENV PATH=/usr/local/bun/bin:$PATH

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompile assets with vite (explicit production mode) and clean old dev/test outputs
RUN SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production VITE_RUBY_MODE=production \
    bun run build \
    && rm -rf public/vite-dev public/vite-test

# Final stage for app image
FROM base

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Set up users and directories
RUN groupadd --system --gid 1000 rails \
    && useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash \
    && mkdir -p /data /var/log/nginx /var/lib/nginx /run/nginx \
    && chown -R 1000:1000 db log storage tmp /data \
    && chown -R www-data:www-data /var/log/nginx /var/lib/nginx /run/nginx \
    && chmod 755 /var/log/nginx /var/lib/nginx

# Copy and set up startup script
COPY config/docker-entrypoint-passenger.sh /usr/local/bin/docker-entrypoint-passenger.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-passenger.sh

# Deployment options
ENV RUBYOPT="--yjit --yjit-exec-mem-size=200 --yjit-mem-size=256 --yjit-call-threshold=20"

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 3000
CMD ["bundle", "exec", "foreman", "start"]
