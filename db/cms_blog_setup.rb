# frozen_string_literal: true
# shareable_constant_value: literal

# Usage: bundle exec rails runner scripts/cms_blog_setup.rb
# Syncs CMS blog layouts from db/cms_seeds/libreverse-blog into the database
# - Sets app_layout = 'application' so Rails head is used
# - Strips YAML front matter before saving content
# - Clears content_cache for affected pages

require 'yaml'

module CMSBlogSync
  module_function

  def run!(site_identifier: 'instance-blog')
    site = Comfy::Cms::Site.find_or_create_by!(identifier: site_identifier) do |s|
      s.label = 'Instance Blog'
      # Use env override so different hostnames can be used per-env. Fallback keeps it local/dev friendly.
      s.hostname = ENV.fetch('CMS_BLOG_HOSTNAME') { 'localhost' }
      # Blank path means root; adjust via CMS_BLOG_PATH if needed later.
      s.path = ENV['CMS_BLOG_PATH'] if ENV['CMS_BLOG_PATH']
    end
    Rails.logger.debug "[cms_blog_setup] Using site id=#{site.id} identifier=#{site.identifier} hostname=#{site.hostname}"

    seeds_root = Rails.root.join("db/cms_seeds/libreverse-blog")
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
      Rails.logger.debug "[cms_blog_setup] Synced layout: #{ident} (app_layout=#{layout.app_layout})"
    end

  Rails.logger.debug "[cms_blog_setup] Done. Updated #{updated_count} layouts."

  # Pages ------------------------------------------------------------------
  sync_pages(site, seeds_root.join('pages'))
  end

  def extract_front_matter(text)
    # Robust extraction supporting Windows/Unix line endings and avoiding false positives.
    if text =~ /\A---\s*\r?\n(.*?)\r?\n---\s*\r?\n(.*)\z/m
      fm_text = Regexp.last_match(1)
      body = Regexp.last_match(2)
      begin
        fm = YAML.safe_load(fm_text, aliases: true) || {}
      rescue StandardError => e
        warn "[cms_blog_setup] front matter parse error: #{e.message}"
        fm = {}
      end
      [ fm, body ]
    else
      [ {}, text ]
    end
  end

  def clear_page_caches_for_layout(site, layout)
    page_ids = site.pages.where(layout_id: layout.id).pluck(:id)
    return if page_ids.empty?

    site.pages.where(id: page_ids).find_each do |page|
      page.update_column(:content_cache, nil)
    end
    Rails.logger.debug "[cms_blog_setup] Cleared content_cache for #{page_ids.size} page(s) using #{layout.identifier}"
  end

  # --- Page syncing ---------------------------------------------------------
  def sync_pages(site, pages_root)
    return unless Dir.exist?(pages_root)

    ensure_root_page(site)
    ensure_not_found_page(site)

    # Traverse directories under pages_root. Convention: 'index' directory represents root page.
    Dir.glob(pages_root.join('**/content.html')).sort.each do |content_path|
      rel_dir = Pathname(content_path).dirname.relative_path_from(pages_root).to_s # e.g. "index/initial-post"
      parts = rel_dir.split(File::SEPARATOR)
      next if parts == [ 'index' ] # root handled separately

      fm, body = extract_front_matter(File.read(content_path))
      layout_identifier = fm['layout'] || 'blog_post'
      layout = site.layouts.find_by(identifier: layout_identifier)
      unless layout
        Rails.logger.warn "[cms_blog_setup] Skipping page #{rel_dir} - layout '#{layout_identifier}' missing"
        next
      end

      parent_page = site.pages.find_by(full_path: '/') # currently only supporting one-level for now
      slug = parts.last # use directory name as slug
      label = fm['label'] || slug.tr('_-', ' ').split.map(&:capitalize).join(' ')
      full_path = "/#{slug}"

      page = site.pages.find_or_initialize_by(full_path: full_path)
      page.slug = slug
      page.label = label
      page.layout = layout
      page.parent = parent_page
      page.is_published = fm.key?('is_published') ? !fm['is_published'].nil? : true
      page.position = fm['position'] if fm['position']
      page.save!

      # Single primary body fragment. If body empty skip.
      if body && !body.strip.empty?
        frag = page.fragments.find_or_initialize_by(identifier: 'content')
        frag.tag = 'wysiwyg'
        frag.content = body.strip
        frag.save!
      end

      page.update!(content_cache: nil) # clear cache
      Rails.logger.debug "[cms_blog_setup] Synced page: #{full_path} (layout=#{layout.identifier})"
    end
  end

  def ensure_root_page(site)
    root = site.pages.find_or_initialize_by(full_path: '/')
    root.slug = nil
    root.label = 'Blog'
    root.layout ||= site.layouts.find_by(identifier: 'blog') || site.layouts.first
    root.is_published = true if root.new_record?
    root.save! if root.changed?
    root
  end

  def ensure_not_found_page(site)
    nf = site.pages.find_or_initialize_by(full_path: '/404')
    nf.slug = '404'
    nf.label = '404'
    nf.layout ||= site.layouts.find_by(identifier: 'blog') || site.layouts.first
    nf.is_published = true if nf.new_record?
    nf.save! if nf.changed?
    nf
  end
end

CMSBlogSync.run!
