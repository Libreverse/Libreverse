# frozen_string_literal: true

# ===== Emoji Replacement Middleware =====
class EmojiReplacer
  require "unicode"
  require "nokogiri"

  EMOJI_REGEX =
    /(?:\p{Extended_Pictographic}(?:\uFE0F)?(?:\u200D\p{Extended_Pictographic}(?:\uFE0F)?)*)|[\u{1F1E6}-\u{1F1FF}]{2}/

  # Default selectors to exclude from emoji replacement
  DEFAULT_EXCLUDE_SELECTORS = %w[script style pre code textarea svg noscript].freeze

  # Paths to exclude from processing completely
  EXCLUDED_PATHS = [
    %r{^/rails/active_storage/},
    %r{^/active_storage/}
  ].freeze

  def initialize(app, options = {})
    @app = app
    @exclude_selectors = options[:exclude_selectors] || DEFAULT_EXCLUDE_SELECTORS
    # Rails.logger.debug { "EmojiReplacer: Initialized with exclude selectors: #{@exclude_selectors.inspect}" }
  end

  def call(env)
    # Skip processing for excluded paths or special content types
    path = env["PATH_INFO"]
    return @app.call(env) if path_excluded?(path)

    return @app.call(env) if request_is_binary?(env)

    # Rails.logger.debug { "EmojiReplacer: Processing request for #{env['PATH_INFO']}" }

    status, headers, body = @app.call(env)

    if headers["Content-Type"]&.include?("text/html")
      # Rails.logger.debug "EmojiReplacer: Detected text/html content type"

      new_body = ""
      body.each do |part|
        # Process HTML with Nokogiri to exclude certain elements
        new_part = if @exclude_selectors.any? && part.include?("<html")
                     process_with_nokogiri(part)
        else
                     replace_emojis(part)
        end

        new_body += new_part
      end

      # Update the body and Content-Length
      body = [ new_body ]
      headers["Content-Length"] = new_body.bytesize.to_s

      # Rails.logger.debug do
      #   "EmojiReplacer: Completed emoji replacement. Updated Content-Length to #{new_body.bytesize}."
      # end
    end

    # Return the modified response
    [ status, headers, body ]
  rescue StandardError => e
    Rails.logger.error "EmojiReplacer: Error processing request: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    safe_status = defined?(status) ? status : 500
    safe_headers = defined?(headers) ? headers : { "Content-Type" => "text/plain" }
    safe_body = defined?(body) ? body : [ "Internal Server Error" ]
    [ safe_status, safe_headers, safe_body ]
  end

  private

  def require_emoji_renderer
    return if defined?(Emoji::Renderer)
    require Rails.root.join("lib/emoji/renderer").to_s
  end

  def path_excluded?(path)
    EXCLUDED_PATHS.any? { |pattern| path.match?(pattern) }
  end

  def request_is_binary?(env)
    # Skip for binary content types, file uploads, etc.
    return true if env["CONTENT_TYPE"]&.start_with?("multipart/form-data")
    return true if env["HTTP_ACCEPT"]&.include?("application/octet-stream")
    return true if env["HTTP_CONTENT_DISPOSITION"]&.include?("attachment")
    return true if env["CONTENT_LENGTH"] && env["CONTENT_LENGTH"].to_i > 1_000_000 # Skip large request bodies

    false
  end

  def process_with_nokogiri(html)
    # Prevent processing of obviously invalid HTML
    if html.blank?
      Rails.logger.warn "EmojiReplacer: Skipping processing of invalid HTML"
      return html
    end

    # Enforce processing timeout to prevent DoS
    Timeout.timeout(1.0) do
      doc = Nokogiri::HTML4.parse(html)

      # Create a set of nodes to exclude
      exclude_nodes = Set.new
      @exclude_selectors.each do |selector|
        doc.css(selector).each do |node|
          exclude_nodes.add(node)
        end
      end

      # Process text nodes that are not within excluded elements
      doc.traverse do |node|
        next unless node.text? && !within_excluded_node?(node, exclude_nodes)

        # Replace emojis with HTML nodes instead of text
        replaced_content = replace_emojis_with_nodes(node.content, doc)

        # Only replace if we actually found and replaced an emoji
        if replaced_content != node.content
          # Create a fragment for the replaced content
          fragment = Nokogiri::HTML4.fragment(replaced_content)
          # Replace the original node with the fragment
          node.replace(fragment)
        end
      end

      doc.to_html
    end
  rescue Timeout::Error
    Rails.logger.error "EmojiReplacer: Processing timeout"
    html
  rescue Nokogiri::XML::SyntaxError => e
    Rails.logger.error "EmojiReplacer: HTML parsing error: #{e.message}"
    html
  rescue StandardError => e
    Rails.logger.error "EmojiReplacer: Processing error: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    html
  end

  def ensure_utf8(str)
    return str if str.encoding == Encoding::UTF_8

    # Attempt to force UTF‑8; if invalid bytes exist, replace them.
    str.force_encoding(Encoding::UTF_8)
    return str if str.valid_encoding?

    str.encode(Encoding::UTF_8, invalid: :replace, undef: :replace)
  rescue StandardError
    str
  end

  def replace_emojis_with_nodes(text, _doc)
    # Rails.logger.debug { "[EmojiReplacer] replace_emojis_with_nodes called" }
    require_emoji_renderer
    Emoji::Renderer.replace(text)
  end

  def within_excluded_node?(node, exclude_nodes)
    return false unless node.respond_to?(:parent)

    current = node
    while current.respond_to?(:parent)
      return true if exclude_nodes.include?(current)

      current = current.parent
    end
    false
  end

  def replace_emojis(text)
    # Rails.logger.debug { "[EmojiReplacer] replace_emojis called" }
    text = ensure_utf8(text)
    require_emoji_renderer
    Emoji::Renderer.replace(text)
  end

  def cache_key(emoji)
    require_emoji_renderer
    Emoji::Renderer.send(:cache_key, emoji)
  end

  def build_inline_svg(emoji)
    require_emoji_renderer
    Emoji::Renderer.build_img_tag(emoji)
  end

  def read_vite_asset_content(path_from_manifest)
    require_emoji_renderer
    Emoji::Renderer.send(:read_vite_asset_content, path_from_manifest)
  end

  def extract_context(text, match_start, match_end, window = 10)
    start_index = [ match_start - window, 0 ].max
    end_index = [ match_end + window, text.length ].min
    text[start_index...end_index]
  end
end
