# config/initializers/solid_cache_prewarm.rb
# Pre-warm Solid Cache table into PostgreSQL buffer cache for better performance
# Based on: https://www.crunchydata.com/blog/solid-cache-for-rails-and-postgresql

Rails.application.config.after_initialize do
  if defined?(SolidCache::Record) && ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
    # Pre-warm the cache table into PostgreSQL's buffer cache for faster access
    # This is especially beneficial for dedicated cache servers
    begin
      SolidCache::Record.connection.execute("SELECT pg_prewarm('solid_cache_entries');")
      Rails.logger.info "Solid Cache table pre-warmed into PostgreSQL buffer cache"
    rescue ActiveRecord::StatementInvalid => e
      # pg_prewarm extension might not be available, log but don't fail
      Rails.logger.warn "pg_prewarm extension not available: #{e.message}"
    rescue => e
      Rails.logger.warn "Failed to pre-warm Solid Cache table: #{e.message}"
    end
  end
end