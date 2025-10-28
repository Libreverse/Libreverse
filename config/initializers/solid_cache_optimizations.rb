# config/initializers/solid_cache_optimizations.rb
# PostgreSQL optimizations for Solid Cache performance
# Based on: https://www.crunchydata.com/blog/solid-cache-for-rails-and-postgresql

Rails.application.config.after_initialize do
  if defined?(SolidCache::Record) && ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
    # Patch Solid Cache to use optimized transaction settings
    module SolidCacheOptimizations
      # Reduce durability guarantees for cache operations to improve performance
      # This trades some durability for speed since cache data can be repopulated
      def execute(sql, name = nil, **options)
        if sql.match?(/\A\s*(INSERT|UPDATE|DELETE)/i) && sql.include?("solid_cache_entries")
          # Use local synchronous commit for cache writes (faster but less durable)
          super("SET LOCAL synchronous_commit TO 'local'; #{sql}", name, **options)
        else
          super
        end
      end
    end

    # Apply the optimization to the cache database connection
    SolidCache::Record.connection_pool.connections.each do |conn|
      conn.extend(SolidCacheOptimizations) if conn.is_a?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
    end

    # Also apply to new connections
    SolidCache::Record.connection_pool.class.prepend(Module.new do
      def new_connection
        conn = super
        conn.extend(SolidCacheOptimizations) if conn.is_a?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
        conn
      end
    end)
  end
end
