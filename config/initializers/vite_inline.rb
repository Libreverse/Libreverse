# frozen_string_literal: true

require "uri"

Rails.application.config.to_prepare do
  ActionView::Base.class_eval do
    # Override ViteRuby's vite_javascript_tag helper to inline all script assets
    def vite_javascript_tag(*sources, **options)
      return super if Rails.env.development?

      # Call original helper to get standard script tags
      original_html = super

      # Inline external scripts by reading asset files from public directory
      inlined_html = original_html.gsub(%r{<script\s+([^>]*?)src=['"]([^'"]+)['"]([^>]*)></script>}) do
        attrs = (Regexp.last_match(1) + Regexp.last_match(3)).strip
        src   = Regexp.last_match(2)
        uri   = URI(src)

        # Only inline local asset files (no host)
        if uri.host.nil?
          asset_path = uri.path
          file_path  = Rails.root.join("public", asset_path.delete_prefix("/"))

          if File.exist?(file_path)
            content = File.read(file_path)
            # Embed script content inline
            "<script \\#{attrs}>#{content}</script>"
          else
            # Fallback to original tag if file missing
            original_html
          end
        else
          # Fallback for remote URLs
          original_html
        end
      end

      # rubocop:disable Rails/OutputSafety -- safe to inline trusted asset files
      inlined_html.html_safe
      # rubocop:enable Rails/OutputSafety
    end
  end
end
