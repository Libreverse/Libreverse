# frozen_string_literal: true
# Development-only: synthetic sample data to drive Metaverse map UI.
# This file is loaded from seeds.rb only in development.
return unless Rails.env.development?

puts '[DevSeed][Metaverse] Creating sample experiences...'

# Use or create a throwaway account as owner
account = Account.first || Account.create!(email: "dev-seed@example.test", username: "devseed", password: SecureRandom.hex(8))

platforms = {
  'HoloWorld' => 20,
  'CyberGrid' => 15,
  'VoxelVerse' => 25
}

# Simple helper to generate bounded pseudo-random coordinate JSON
random_coord = ->(scale = 1000.0) do
  { x: (rand * scale).round(2), y: (rand * scale).round(2) }.to_json
end

platforms.each do |platform, count|
  existing = Experience.where(metaverse_platform: platform).count
  needed = [count - existing, 0].max
  next if needed.zero?

  needed.times do |i|
    title = "#{platform} Experience #{existing + i + 1}"
    Experience.create!(
      title: title,
      description: "Synthetic dev sample for #{platform} (#{i + 1}).",
      author: 'DevSeeder',
      account: account,
      approved: true,
      federate: false,
      offline_available: false,
      metaverse_platform: platform,
      metaverse_coordinates: (rand < 0.15 ? nil : random_coord.call), # Some experiences intentionally lack coords
      metaverse_metadata: { category: %w[game social art edu sim].sample }.to_json,
      html_file: (begin
        # Attach a tiny HTML blob (skipped validations if necessary) - using StringIO
        io = StringIO.new("<html><body><h1>#{ERB::Util.html_escape(title)}</h1><p>Sample content.</p></body></html>")
        io.set_encoding(Encoding::UTF_8)
        { io: io, filename: "#{title.parameterize}.html", content_type: 'text/html' }
      end)
    )
  rescue StandardError => e
    Rails.logger.warn "[DevSeed][Metaverse] Failed to create #{title}: #{e.message}"
  end
end

puts '[DevSeed][Metaverse] Sample experiences present:'
platforms.keys.each do |p|
  puts "  - #{p}: #{Experience.where(metaverse_platform: p).count} experiences"
end

puts '[DevSeed][Metaverse] Done.'
