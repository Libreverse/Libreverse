# frozen_string_literal: true

# Usage: bundle exec rails runner scripts/cms_blog_setup.rb
# Syncs CMS blog layouts from db/cms_seeds/libreverse-blog into the database
# - Sets app_layout = 'application' so Rails head is used
# - Strips YAML front matter before saving content
# - Clears content_cache for affected pages

require 'yaml'

module CMSBlogSync
  module_function

  def run!(site_identifier: 'instance-blog')
    site = Comfy::Cms::Site.find_by(identifier: site_identifier)
    abort "[cms_blog_setup] Site not found: #{site_identifier}" unless site

    seeds_root = Rails.root.join('db', 'cms_seeds', 'libreverse-blog')
    layouts_dir = seeds_root.join('layouts')
    abort "[cms_blog_setup] Layouts dir missing: #{layouts_dir}" unless Dir.exist?(layouts_dir)

    updated_count = 0

    Dir.glob(layouts_dir.join('*.html')).sort.each do |path|
      fm, body = extract_front_matter(File.read(path))

      ident = (fm['identifier'] if fm.is_a?(Hash)) || File.basename(path, '.html')
      label = (fm['label'] if fm.is_a?(Hash)) || ident.to_s.tr('_-', ' ').split.map(&:capitalize).join(' ')
      app_layout = (fm['app_layout'] if fm.is_a?(Hash)) || 'application'

      layout = site.layouts.find_or_initialize_by(identifier: ident)
      layout.label = label if layout.label.blank?
      layout.app_layout = app_layout
      layout.content = body.to_s.strip
      layout.save!

      # Clear caches for pages using this layout (and immediate children layouts)
      clear_page_caches_for_layout(site, layout)

      updated_count += 1
      puts "[cms_blog_setup] Synced layout: #{ident} (app_layout=#{layout.app_layout})"
    end

    puts "[cms_blog_setup] Done. Updated #{updated_count} layouts."
  end

  def extract_front_matter(text)
    return [{}, text] unless text.start_with?('---')
    parts = text.split(/^---\s*$\n/, 3) # leading empty, front matter, body
    if parts.length >= 3
      fm_text = parts[1]
      body = parts[2]
      begin
        fm = YAML.safe_load(fm_text, aliases: true) || {}
      rescue => e
        warn "[cms_blog_setup] front matter parse error: #{e.message}"
        fm = {}
      end
      [fm, body]
    else
      [{}, text]
    end
  end

  def clear_page_caches_for_layout(site, layout)
    page_ids = site.pages.where(layout_id: layout.id).pluck(:id)
    return if page_ids.empty?
    site.pages.where(id: page_ids).update_all(content_cache: nil)
    puts "[cms_blog_setup] Cleared content_cache for #{page_ids.size} page(s) using #{layout.identifier}"
  end
end

CMSBlogSync.run!
