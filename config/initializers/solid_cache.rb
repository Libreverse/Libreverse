# Configure SolidCache to use the cache database
Rails.application.config.after_initialize do
  SolidCache::Record.connects_to database: { writing: :cache, reading: :cache } if defined?(SolidCache::Record)
end

# Configure Solid Cache logger
Rails.application.config.solid_cache.logger = Rails.logger

# Optimize PostgreSQL transactions for Solid Cache performance
# Based on: https://www.crunchydata.com/blog/solid-cache-for-rails-and-postgresql
if defined?(SolidCache::Record)
  module SolidCachePostgresOptimizations
    # Patch Solid Cache to use optimized PostgreSQL transaction settings
    module TransactionOptimizations
      def transaction(**options, &block)
        if connection.adapter_name == 'PostgreSQL' && options[:requires_new].nil?
          # Use local synchronous_commit for better performance on cache operations
          # This provides local durability but reduces network overhead for replication
          connection.execute("SET LOCAL synchronous_commit = 'local'")
        end
        super
      end
    end

    # Apply the patch to SolidCache::Record
    SolidCache::Record.extend(TransactionOptimizations)
  end
end
