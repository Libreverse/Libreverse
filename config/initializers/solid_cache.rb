# frozen_string_literal: true

# Configure SolidCache to use the cache database
Rails.application.config.after_initialize do
  SolidCache::Record.connects_to database: { writing: :cache, reading: :cache } if defined?(SolidCache::Record)
end

