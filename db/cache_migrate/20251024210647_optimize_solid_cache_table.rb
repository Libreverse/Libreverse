# frozen_string_literal: true
# shareable_constant_value: literal

class OptimizeSolidCacheTable < ActiveRecord::Migration[8.0]
  def up
    # PostgreSQL optimizations for Solid Cache performance
    # Based on: https://www.crunchydata.com/blog/solid-cache-for-rails-and-postgresql

    # Only apply optimizations if we're using PostgreSQL
    return unless connection.adapter_name == 'PostgreSQL'

      # Disable WAL for the cache table to reduce write IO
      # Cache data can be lost and repopulated, so durability guarantees are less critical
      execute "ALTER TABLE solid_cache_entries SET UNLOGGED;"

      # Optimize autovacuum settings for better performance on cache table
      # Reduce scale factor so vacuum triggers earlier, and adjust cost settings
      execute <<-SQL
        ALTER TABLE solid_cache_entries SET (
          autovacuum_vacuum_scale_factor = 0.01,
          autovacuum_vacuum_cost_delay = 10,
          autovacuum_vacuum_cost_limit = 200
        );
      SQL

      # Optimize random_page_cost for better query planning on SSDs
      # Default was designed for HDDs, reduce it to favor index scans
      execute "ALTER DATABASE #{connection.current_database} SET random_page_cost = 1.1;"

    # NOTE: synchronous_commit optimization is applied at transaction level
    # in the Solid Cache initializer, not at table level
  end

  def down
    # Revert optimizations if we're using PostgreSQL
    return unless connection.adapter_name == 'PostgreSQL'

      # Re-enable WAL logging
      execute "ALTER TABLE solid_cache_entries SET LOGGED;"

      # Reset autovacuum settings to defaults
      execute <<-SQL
        ALTER TABLE solid_cache_entries RESET (
          autovacuum_vacuum_scale_factor,
          autovacuum_vacuum_cost_delay,
          autovacuum_vacuum_cost_limit
        );
      SQL

      # Reset random_page_cost to default value
      execute "ALTER DATABASE #{connection.current_database} RESET random_page_cost;"
  end
end
