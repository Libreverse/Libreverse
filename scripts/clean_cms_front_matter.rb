# frozen_string_literal: true

# Usage: bundle exec rails runner scripts/clean_cms_front_matter.rb

site = Comfy::Cms::Site.find_by(identifier: 'instance-blog')
abort('CMS site instance-blog not found') unless site

FRONT_MATTER_RE = /---\s*\n.*?\n---\s*\n/m

# Remove YAML-like front matter blocks that include known Comfy keys
strip_yaml = lambda do |text|
  return text unless text.is_a?(String)

  text.gsub(FRONT_MATTER_RE) do |blk|
    blk.include?('label:') || blk.include?('identifier:') || blk.include?('content_type:') || blk.include?('layout:') ? '' : blk
  end
end

updated = 0

# Clean Layouts
site.layouts.find_each do |layout|
  cleaned = strip_yaml.call(layout.content)
  next if cleaned == layout.content

  layout.update!(content: cleaned)
  puts "Cleaned layout: #{layout.identifier}"
  updated += 1
end

# Clean Snippets
site.snippets.find_each do |snip|
  cleaned = strip_yaml.call(snip.content)
  next if cleaned == snip.content

  snip.update!(content: cleaned)
  puts "Cleaned snippet: #{snip.identifier}"
  updated += 1
end

# Clean Page Fragments
Comfy::Cms::Page.where(site_id: site.id).find_each do |page|
  page_changed = false
  page.fragments.where.not(content: [ nil, '' ]).find_each do |frag|
    cleaned = strip_yaml.call(frag.content)
    next if cleaned == frag.content

    frag.update!(content: cleaned)
    puts "  Cleaned fragment #{frag.identifier} on page #{page.full_path}"
    page_changed = true
    updated += 1
  end
  if page_changed
  page.update!(content_cache: nil)
    puts "Cleared content_cache for: #{page.full_path}"
  end
end

puts "Done. Updated #{updated} records."
