# Bootsnap Performance Optimization
require "bootsnap"

# Use Rails.env instead of ENV
Bootsnap.setup(
  cache_dir: Rails.root.join("tmp/cache"),
  ignore_directories: [ "node_modules" ],
  development_mode: Rails.env.development?,
  load_path_cache: true,
  compile_cache_iseq: true,
  compile_cache_yaml: true,
  compile_cache_json: true,
  readonly: false
)
