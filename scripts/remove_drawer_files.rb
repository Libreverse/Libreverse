# frozen_string_literal: true

# Utility to delete legacy drawer assets
paths = [
  Rails.root.join('app/stylesheets/drawer.scss'),
  Rails.root.join('app/stylesheets/components/_drawer.scss'),
]

paths.each do |p|
  if File.exist?(p)
    File.delete(p)
    puts "Deleted #{p}"
  else
    puts "Missing #{p}, skipped"
  end
end
