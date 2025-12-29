# frozen_string_literal: true
# shareable_constant_value: literal

# Set up ComfortableMediaSurfer blog
Rails.logger.debug "Setting up blog with ComfortableMediaSurfer..."
begin
  load Rails.root.join("db/cms_blog_setup.rb")
rescue StandardError => e
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
