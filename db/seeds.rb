# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Setup ComfortableMediaSurfer blog
Rails.logger.debug "Setting up blog with ComfortableMediaSurfer..."
load Rails.root.join("db/cms_blog_setup.rb")

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
