# frozen_string_literal: true

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
    request.path.start_with?('/blog')
  end

  # Returns navigation items for the blog
  def blog_navigation_items
    [
      { label: 'Blog Home', path: blog_url },
      { label: 'Latest Posts', path: "#{blog_url}#latest" },
    ]
  end

  # Returns recent blog posts for sidebar/navigation
  # This can be used in your main application to show recent blog posts
  def recent_blog_posts(limit: 5)
    return [] unless defined?(Comfy::Cms::Site)
    
    blog_site = Comfy::Cms::Site.find_by(identifier: 'instance-blog')
    return [] unless blog_site

    blog_site.pages
             .published
             .where.not(parent_id: nil) # Exclude root page
             .order(created_at: :desc)
             .limit(limit)
             .map do |page|
      {
        title: page.fragments.find_by(identifier: 'title')&.content&.strip&.gsub(/^---\s*/, '') || page.label,
        url: "/blog#{page.full_path}",
        published_at: page.fragments.find_by(identifier: 'published_at')&.content&.strip&.gsub(/^---\s*['"]?|['"]?\s*$/, ''),
        excerpt: page.fragments.find_by(identifier: 'meta_description')&.content&.strip&.gsub(/^---\s*/, '') || ''
      }
    end
  rescue StandardError => e
    Rails.logger.warn "Error fetching recent blog posts: #{e.message}"
    []
  end
end
