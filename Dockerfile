# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.4.1
FROM quay.io/evl.ms/fullstaq-ruby:${RUBY_VERSION}-jemalloc-slim AS base

# Rails app lives here
WORKDIR /rails

# Set production environment
ENV BUNDLE_DEPLOYMENT="1" \
  BUNDLE_PATH="/usr/local/bundle" \
  BUNDLE_WITHOUT="development:test" \
  RAILS_ENV="production"

# Update gems and bundler
RUN gem update --system --no-document \
  && gem install -N bundler

# Throw-away build stages to reduce size of final image
FROM base AS prebuild

# Install packages needed to build gems
RUN --mount=type=cache,id=dev-apt-cache,sharing=locked,target=/var/cache/apt \
  --mount=type=cache,id=dev-apt-lib,sharing=locked,target=/var/lib/apt \
  apt-get update -qq \
  && apt-get install --no-install-recommends -y build-essential curl default-libmysqlclient-dev libvips libyaml-dev unzip

FROM prebuild AS bun

# Install Bun
ARG BUN_VERSION=1.1.38
ENV BUN_INSTALL=/usr/local/bun
ENV PATH=/usr/local/bun/bin:$PATH
RUN curl -fsSL https://bun.sh/install | bash -s -- "bun-v${BUN_VERSION}"

# Install node modules
COPY package.json bun.lockb ./
RUN --mount=type=cache,id=bld-bun-cache,target=/root/.bun \
  bun install --frozen-lockfile

FROM prebuild AS build

# Install application gems
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

# Precompiling assets for production using vite without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails vite:build

# Final stage for app image
FROM base

# Install packages needed for deployment
RUN --mount=type=cache,id=dev-apt-cache,sharing=locked,target=/var/cache/apt \
  --mount=type=cache,id=dev-apt-lib,sharing=locked,target=/var/lib/apt \
  apt-get update -qq \
  && apt-get install --no-install-recommends -y curl default-mysql-client imagemagick libvips

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
ARG UID=1000 \
  GID=1000
RUN groupadd -f -g $GID rails \
  && useradd -u $UID -g $GID rails --create-home --shell /bin/bash \
  && chown -R rails:rails db log storage tmp
USER rails:rails

# Deployment options
ENV RUBY_YJIT_ENABLE="1"

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["./bin/rails", "server"]
