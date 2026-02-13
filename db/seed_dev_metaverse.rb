# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# Development-only: synthetic sample data to drive Metaverse map UI.
# This file is loaded from seeds.rb only in development.
return unless Rails.env.development?

Rails.logger.debug '[DevSeed][Metaverse] Creating sample experiences...'

# Ensure an account exists for ownership
account = Account.find_or_create_by!(username: "metaverse-system") do |acc|
  acc.admin = true
  acc.status = 2
end

platforms = {
  'HoloWorld' => 20,
  'CyberGrid' => 15,
  'VoxelVerse' => 25
}

# Simple helper to generate bounded pseudo-random coordinate JSON
random_coord = lambda do |scale = 1000.0|
  { x: (rand * scale).round(2), y: (rand * scale).round(2) }.to_json
end

platforms.each do |platform, count|
  existing = Experience.where(metaverse_platform: platform).count
  needed = [ count - existing, 0 ].max
  next if needed.zero?

  # Temporarily disable vectorization callbacks during bulk seeding to avoid after_commit errors
  Experience.skip_callback(:commit, :after, :schedule_vectorization) if Experience.respond_to?(:skip_callback)

  needed.times do |i|
    title = "#{platform} Experience #{existing + i + 1}"
    exp = Experience.new(
      title: title,
      description: "Synthetic dev sample for #{platform} (#{i + 1}).",
      author: 'DevSeeder',
      account: account,
      flags: 1, # Set approved flag (bit position 1)
      metaverse_platform: platform,
      metaverse_coordinates: (rand < 0.15 ? nil : random_coord.call), # Some experiences intentionally lack coords
      metaverse_metadata: { category: %w[game social art edu sim].sample }.to_json
    )

    html_io = StringIO.new("<html><body><h1>#{ERB::Util.html_escape(title)}</h1><p>Sample content.</p></body></html>")
    html_io.set_encoding(Encoding::UTF_8)
    exp.html_file.attach(io: html_io, filename: "#{title.parameterize}.html", content_type: 'text/html')

    exp.save!
  rescue StandardError => e
    Rails.logger.warn "[DevSeed][Metaverse] Failed to create #{title}: #{e.message}\n#{e.backtrace&.take(10)&.join("\n")}"
  end
ensure
  Experience.set_callback(:commit, :after, :schedule_vectorization) if Experience.respond_to?(:set_callback)
end

Rails.logger.debug '[DevSeed][Metaverse] Sample experiences present:'
platforms.each_key do |p|
  Rails.logger.debug "  - #{p}: #{Experience.where(metaverse_platform: p).count} experiences"
end

Rails.logger.debug '[DevSeed][Metaverse] Done.'
