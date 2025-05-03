# frozen_string_literal: true

module EmojiHelper
  require "nokogiri"
  require "cgi"

  # Delegate constants to the central renderer
  EMOJI_REGEX = Emoji::Renderer::EMOJI_REGEX

  # Public: Replaces emoji characters in +text+ with inline SVG <img> tags.
  # Returns an HTML-safe string with basic sanitization applied.
  def render_emojis(text)
    Rails.logger.debug { "[EmojiHelper] render_emojis called" }
    sanitized = Emoji::Renderer.replace(text.to_s)
    sanitized_html = sanitize(sanitized, tags: allowed_html_tags, attributes: allowed_html_attributes)
    Rails.logger.debug { "[EmojiHelper] render_emojis returning length=#{sanitized_html.bytesize}" }
    sanitized_html
  end

  # Processes arbitrary HTML content (String) replacing emoji characters within
  # text nodes (excluding <code>, <pre>, etc.). Returns an HTML-safe String.
  def process_html_with_emojis(html_content)
    Rails.logger.debug { "[EmojiHelper] process_html_with_emojis length=#{html_content&.bytesize || 0}" }
    return "" if html_content.blank?

    doc = Nokogiri::HTML.fragment(html_content)
    doc.traverse do |node|
      next unless node.text? && node.content.present?
      next if node.ancestors.any? { |ancestor| %w[code pre].include?(ancestor.name) }

      node.content = Emoji::Renderer.replace(node.content)
    end

    output = doc.to_html
    Rails.logger.debug { "[EmojiHelper] process_html_with_emojis output_length=#{output.bytesize}" }
    output
  end

  # Convenience helpers
  def simple_format_text(text)
    Rails.logger.debug { "[EmojiHelper] simple_format_text called" }
    return "" if text.blank?

    sanitized = Emoji::Renderer.replace(text)
    sanitized_html = sanitize(sanitized, tags: allowed_html_tags, attributes: allowed_html_attributes)
    Rails.logger.debug { "[EmojiHelper] simple_format_text returning length=#{sanitized_html.bytesize}" }
    sanitized_html
  end

  def html_escape(text)
    Rails.logger.debug { "[EmojiHelper] html_escape called" }
    sanitize(CGI.escapeHTML(text.to_s))
  end

  private

  def allowed_html_tags
    %w[img p br strong em]
  end

  def allowed_html_attributes
    %w[src alt class loading decoding fetchpriority draggable tabindex]
  end
end
