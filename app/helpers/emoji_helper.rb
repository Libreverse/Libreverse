# frozen_string_literal: true

module EmojiHelper
  require "base64"
  require "nokogiri"
  require "uri"
  require "digest/sha1"
  require "erb"

  # Matches standard emojis, including sequences with ZWJ and skin tone modifiers
  EMOJI_REGEX = /(?:\p{Extended_Pictographic}(?:\p{Emoji_Modifier})?(?:\u{FE0F})?(?:\u{200D}\p{Extended_Pictographic}(?:\p{Emoji_Modifier})?(?:\u{FE0F})?)*)|[\u{1F1E6}-\u{1F1FF}]{2}/

  # Replaces emojis in a given text string with inline SVG <img> tags.
  # Uses caching to avoid redundant SVG processing.
  # Returns HTML-safe string.
  def render_emojis(text)
    # Ensure input is a string
    text_str = text.to_s
    return sanitize(text_str) unless text_str.match?(EMOJI_REGEX)

    # Use gsub to find and replace emojis with their img tags
    processed_text = text_str.gsub(EMOJI_REGEX) do |emoji|
      # Use caching to build/retrieve the img tag
      Rails.cache.fetch(emoji_cache_key(emoji), expires_in: 1.week) do
        build_emoji_img_tag(emoji)
      end || emoji
    end

    # Sanitize the final result
    sanitize(processed_text, tags: allowed_html_tags, attributes: allowed_html_attributes)
  end

  # Uses Nokogiri to safely parse and process HTML content
  def process_html_with_emojis(html_content)
    return "" if html_content.blank?

    doc = Nokogiri::HTML.fragment(html_content)
    doc.traverse do |node|
      # Only process text nodes, not elements or attributes
      next unless node.text? && node.content.present?
      next if node.ancestors.any? { |a| %w[code pre].include?(a.name) }

      # Replace emoji codes with image tags
      node.content = render_emojis(node.content) if node.content.match?(EMOJI_REGEX)
    end

    # Return processed HTML as a safe string
    doc.to_html
  end

  # Escapes HTML and marks it as safe
  def simple_format_text(text)
    return "" if text.blank?

    # Escape HTML first
    processed_text = render_emojis(text)
    sanitize(processed_text, tags: allowed_html_tags, attributes: allowed_html_attributes)
  end

  # Ensures HTML is escaped and safe
  def html_escape(text)
    sanitize(CGI.escapeHTML(text || ""))
  end

  private

  # Defines the allowed HTML tags for sanitization.
  def allowed_html_tags
    # Allow basic formatting (p, br, strong, em) + the emoji img tag
    %w[img p br strong em]
  end

  # Defines the allowed HTML attributes for sanitization.
  def allowed_html_attributes
    # Allow attributes for the emoji img tag + common attributes like class
    %w[src alt class loading decoding fetchpriority draggable tabindex]
  end

  # Generates a cache key for a given emoji.
  def emoji_cache_key(emoji)
    "emoji_helper/v13/#{Digest::SHA1.hexdigest(emoji)}"
  end

  # Builds the inline SVG <img> tag for a given emoji using URL encoding.
  def build_emoji_img_tag(emoji)
    codepoints = emoji.codepoints.reject { |cp| cp == 0xFE0F }.map { |cp| cp.to_s(16) }.join("-")

    begin
      svg_path_from_vite = ViteRuby.instance.manifest.path_for("emoji/#{codepoints}.svg", { type: :image })
    rescue ViteRuby::MissingEntrypointError
      Rails.logger.warn "EmojiHelper: SVG manifest entry not found for emoji '#{emoji}' with codepoints '#{codepoints}'."
      return nil
    end

    return nil if svg_path_from_vite.blank?

    svg_content = read_vite_asset_content(svg_path_from_vite)

    if svg_content
      encoded_svg = ERB::Util.url_encode(svg_content)
      %(<img src="data:image/svg+xml,#{encoded_svg}" alt="#{CGI.escapeHTML(emoji)}" class="emoji" loading="eager" decoding="async" fetchpriority="low" draggable="false" tabindex="-1">)
    end
  rescue StandardError => e
    Rails.logger.error "EmojiHelper: Error building SVG tag for emoji '#{emoji}': #{e.message}"
    nil
  end

  # Helper to read asset content based on environment
  def read_vite_asset_content(path_from_manifest)
    return nil if path_from_manifest.blank?

    if Rails.env.development? || Rails.env.test?
      begin
        vite_uri = URI.join(ViteRuby.instance.config.public_base_url, path_from_manifest)
        response_body = Net::HTTP.get(vite_uri)
        response_body.presence
      rescue StandardError => e
        Rails.logger.error "Error fetching asset from Vite dev server: #{e.message} for URI: #{vite_uri}"
        nil
      end
    else
      relative_path = path_from_manifest.sub(%r{^/?#{ViteRuby.instance.config.public_output_dir}/}, "")
      public_path = Rails.root.join("public", ViteRuby.instance.config.public_output_dir, relative_path)
      File.exist?(public_path) ? File.read(public_path) : nil
    end
  rescue StandardError => e
    Rails.logger.error "Error reading Vite asset content for path '#{path_from_manifest}': #{e.message}"
    nil
  end
end
