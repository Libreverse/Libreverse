# frozen_string_literal: true

# Bootsnap Performance Optimization
require "bootsnap"

# Fasterer: using block form of fetch for efficiency
env = ENV.fetch("RAILS_ENV") { "development" }
Bootsnap.setup(
  cache_dir: "tmp/cache",
  ignore_directories: [ "node_modules" ],
  development_mode: env == "development",
  load_path_cache: true,
  compile_cache_iseq: true,
  compile_cache_yaml: true,
  compile_cache_json: true,
  readonly: true
)
