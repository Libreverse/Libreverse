# frozen_string_literal: true
# shareable_constant_value: literal

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# This runs once during db:seed (or db:setup). It connects to TiDB and applies
# aggressive performance-tuning system variables via SQL.
# These are the "max" settings we discussed: focused on plan caching, optimizer,
# concurrency, statistics, and memory for high-throughput OLTP/high-concurrency Rails apps.
#
# WARNING: These are aggressive – they increase memory usage and parallelism.
# Test thoroughly on staging! Monitor TiDB Dashboard for OOM, CPU, and plan quality.
#
# Most are GLOBAL scope and dynamic (take effect immediately, cluster-wide).
# They do NOT persist across TiDB restarts – for persistence, add them to your
# TiUP/K8s topology under server_configs.tidb (TOML format).

# db/seeds.rb

puts "Applying aggressive TiDB performance tuning variables (corrected for scope & value types)..."

# Helper to execute SET safely
def set_var(scope, var, value)
  sql = case scope
        when :global
          "SET GLOBAL #{var} = #{value}"
        when :session
          "SET SESSION #{var} = #{value}"
        when :both
          "SET GLOBAL #{var} = #{value}"
        else
          raise "Unknown scope"
        end

  begin
    ActiveRecord::Base.connection.execute(sql)
    puts "Applied: #{sql}"
  rescue => e
    puts "Warning: Failed to apply '#{sql}': #{e.message}"
  end
end

# Plan Caching (big wins for Rails)
set_var(:both,  'tidb_enable_non_prepared_plan_cache', 'ON')
set_var(:both,  'tidb_enable_non_prepared_plan_cache_for_dml', 'ON')
set_var(:global,'tidb_enable_instance_plan_cache', 'ON')                     # GLOBAL only (v8.4+)
set_var(:global,'tidb_instance_plan_cache_max_size', '4294967296')           # 4GB in bytes (adjust to your RAM)
set_var(:both,  'tidb_ignore_prepared_cache_close_stmt', 'ON')
set_var(:both,  'tidb_non_prepared_plan_cache_size', '100000')
set_var(:both,  'tidb_plan_cache_max_plan_size', '0')                        # Unlimited

# Optimizer Boosters
set_var(:both, 'tidb_opt_agg_push_down', 'ON')
set_var(:session, 'tidb_opt_distinct_agg_push_down', 'ON')                   # SESSION only
set_var(:both, 'tidb_opt_skew_distinct_agg', 'ON')
set_var(:both, 'tidb_opt_limit_push_down_threshold', '1000000')
set_var(:both, 'tidb_opt_projection_push_down', 'ON')
set_var(:both, 'tidb_opt_enable_hash_join', 'ON')
set_var(:both, 'tidb_opt_enable_late_materialization', 'ON')
set_var(:both, 'tidb_opt_enable_mpp_shared_cte_execution', 'ON')
set_var(:both, 'tidb_opt_insubq_to_join_and_agg', 'ON')
set_var(:both, 'tidb_opt_join_reorder_threshold', '0')

# Concurrency & Execution
set_var(:both, 'tidb_max_chunk_size', '128')
set_var(:both, 'tidb_distsql_scan_concurrency', '20')
set_var(:both, 'tidb_executor_concurrency', '16')
set_var(:both, 'tidb_index_join_batch_size', '32768')
set_var(:both, 'tidb_index_lookup_concurrency', '8')
set_var(:both, 'tidb_index_serial_scan_concurrency', '8')

# Statistics
set_var(:global, 'tidb_analyze_column_options', "'ALL'")                      # GLOBAL only
set_var(:both, 'tidb_stats_load_sync_wait', '5000')

# Transaction/Read Optimizations (if your app can tolerate relaxed consistency)
set_var(:global, 'tidb_rc_read_check_ts', 'ON')                               # GLOBAL only
set_var(:both, 'tidb_guarantee_linearizability', 'OFF')

# Memory Tweaks (monitor closely!)
set_var(:both, 'tidb_mem_quota_query', '8589934592')                          # 8GB in bytes (e.g., 8 * 1024**3)
set_var(:global, 'tidb_server_memory_limit', '0')                             # Unlimited (or e.g. '80%' or bytes)

puts "TiDB performance variables applied!"

# Setup ComfortableMediaSurfer blog
Rails.logger.debug "Setting up blog with ComfortableMediaSurfer..."
begin
  load Rails.root.join("db/cms_blog_setup.rb")
rescue => e
  Rails.logger.warn "CMS blog setup failed: #{e.message}. Continuing with other seeds..."
end

# Development-only sample data for Metaverse map visualization
if Rails.env.development?
  sample_seed_file = Rails.root.join('db/seed_dev_metaverse.rb')
  if File.exist?(sample_seed_file)
    Rails.logger.debug 'Seeding development metaverse sample data...'
    load sample_seed_file
  else
    Rails.logger.warn 'Missing dev metaverse seed file (db/seed_dev_metaverse.rb)'
  end
end
