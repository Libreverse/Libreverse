# frozen_string_literal: true

# Configure SolidCache to use the cache database
Rails.application.config.after_initialize do
  if defined?(SolidCache::Record)
    SolidCache::Record.connects_to database: { writing: :cache, reading: :cache }
  end
end
