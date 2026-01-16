# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# Helper methods for integrating ComfortableMediaSurfer blog with the main application
module BlogHelper
  # Returns the URL for the blog homepage
  def blog_url
    "/blog"
  end

  # Returns the URL for a specific blog post
  def blog_post_url(slug)
    "/blog/#{slug}"
  end

  # Checks if the current page is within the blog section
  def in_blog_section?
    request.path.start_with?("/blog")
  end

  # Returns navigation items for the blog
  def blog_navigation_items
    [
      { label: "Blog Home", path: blog_url },
      { label: "Latest Posts", path: "#{blog_url}#latest" }
    ]
  end

  # Returns recent blog posts for sidebar/navigation
  # This can be used in your main application to show recent blog posts
  def recent_blog_posts(limit: 5)
    return [] unless defined?(Comfy::Cms::Site)

    blog_site = Comfy::Cms::Site.find_by(identifier: "instance-blog")
    return [] unless blog_site

    blog_site.pages
             .published
             .where.not(parent_id: nil) # Exclude root page
             .order(created_at: :desc)
             .limit(limit)
             .map do |page|
      {
        title: page.fragments.find_by(identifier: "title")&.content&.strip&.gsub(/^---\s*/, "") || page.label,
        url: "/blog#{page.full_path}",
        published_at: page.fragments.find_by(identifier: "published_at")&.content&.strip&.gsub(/^---\s*['"]?|['"]?\s*$/, ""),
        excerpt: page.fragments.find_by(identifier: "meta_description")&.content&.strip&.gsub(/^---\s*/, "") || ""
      }
    end
  rescue StandardError => e
    Rails.logger.warn "Error fetching recent blog posts: #{e.message}"
    []
  end

  # Renders full blog post listing (used inside CMS layout via {{ cms:helper blog_post_list }})
  # Includes label, published_at (if available) and meta_description excerpt.
  # Uses basic HTML; styling handled by layout classes.
  def blog_post_list
    site = Comfy::Cms::Site.find_by(identifier: "instance-blog")
    return "".html_safe unless site

    root = site.pages.find_by(full_path: "/")
    return "".html_safe unless root

    pages = root.children.published.where.not(slug: "404").order(created_at: :desc)
    safe_join(pages.map { |page| blog_post_article(page) })
  rescue StandardError => e
    Rails.logger.warn "Error rendering blog_post_list: #{e.message}"
    "".html_safe
  end

  private

  def blog_post_article(page)
    title_frag = page.fragments.find_by(identifier: "title")
    published_frag = page.fragments.find_by(identifier: "published_at")
    meta_frag = page.fragments.find_by(identifier: "meta_description")
    content_frag = page.fragments.find_by(identifier: "content")

    title = title_frag&.content&.strip.presence || page.label
    published_at = published_frag&.content&.strip.presence
    meta_desc = meta_frag&.content&.strip.presence
    # If no meta description, build a short excerpt from content
    if meta_desc.blank? && content_frag&.content.present?
      text = ActionView::Base.full_sanitizer.sanitize(content_frag.content)
      meta_desc = "#{text.tr("\n", ' ').squeeze(' ')[0..180].strip}…" if text.present?
    end
    if meta_desc.blank?
      raw_content = page.fragments.find_by(identifier: "content")&.content.to_s
      # Strip HTML tags and condense whitespace for an excerpt
      text_only = ActionView::Base.full_sanitizer.sanitize(raw_content).squeeze(" ")
      meta_desc = text_only[0, 220].to_s.strip
      meta_desc << "…" if text_only.length > 220
    end

    content_tag(:article, class: "blog-post") do
      # Entire card is a single interactive element. Use a block link.
      link_to("/blog#{page.full_path}", class: "blog-post__link", 'aria-label': title) do
        safe_join([
          content_tag(:h2, title, class: "blog-post__title"),
          (content_tag(:div, class: "post-meta mb-3") { content_tag(:span, published_at, class: "text-muted") } if published_at.present?),
          (content_tag(:p, meta_desc, class: "lead") if meta_desc.present?)
        ].compact)
      end
    end
  end
end
