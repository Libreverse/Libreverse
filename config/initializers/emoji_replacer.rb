# frozen_string_literal: true

# ===== Emoji Replacement =====
class EmojiReplacer
  require "unicode"
  require "nokogiri"

  EMOJI_REGEX =
    /(?:\p{Extended_Pictographic}(?:\uFE0F)?(?:\u200D\p{Extended_Pictographic}(?:\uFE0F)?)*)|[\u{1F1E6}-\u{1F1FF}]{2}/

  # Default selectors to exclude from emoji replacement
  DEFAULT_EXCLUDE_SELECTORS = %w[script style pre code textarea svg noscript].freeze

  def initialize(app, options = {})
    @app = app
    @exclude_selectors = options[:exclude_selectors] || DEFAULT_EXCLUDE_SELECTORS
    Rails.logger.debug { "EmojiReplacer: Initialized with exclude selectors: #{@exclude_selectors.inspect}" }
  end

  def call(env)
    Rails.logger.debug { "EmojiReplacer: Processing request for #{env['PATH_INFO']}" }

    status, headers, body = @app.call(env)

    if headers["Content-Type"]&.include?("text/html")
      Rails.logger.debug "EmojiReplacer: Detected text/html content type"

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

      Rails.logger.debug do
        "EmojiReplacer: Completed emoji replacement. Updated Content-Length to #{new_body.bytesize}."
      end
    else
      Rails.logger.debug "EmojiReplacer: Skipping emoji replacement. Content-Type is not text/html."
    end

    # Return the modified response
    [ status, headers, body ]
  rescue StandardError => e
    Rails.logger.error "EmojiReplacer: Error processing request: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    [ 500, { "Content-Type" => "text/plain" }, [ "Internal Server Error" ] ]
  end

  private

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
    text = ensure_utf8(text)
    return text unless text.match?(EMOJI_REGEX)

    text.gsub(EMOJI_REGEX) do |emoji|
      match_data = Regexp.last_match
      context = extract_context(text, match_data.begin(0), match_data.end(0))
      Rails.logger.debug { "EmojiReplacer: Detected emoji '#{emoji}' around: '#{context}'" }

      # Use caching
      img_tag = Rails.cache.fetch(cache_key(emoji), expires_in: 12.hours) do
        Rails.logger.debug { "EmojiReplacer: Cache miss for emoji '#{emoji}'. Building inline SVG." }
        build_inline_svg(emoji)
      end

      if img_tag
        Rails.logger.debug { "EmojiReplacer: Replacing emoji '#{emoji}' with img tag." }
        img_tag
      else
        Rails.logger.warn "EmojiReplacer: Failed to build img tag for emoji '#{emoji}'. Using original emoji."
        emoji
      end
    end
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
    text = ensure_utf8(text)
    text.gsub(EMOJI_REGEX) do |emoji|
      match_data = Regexp.last_match
      context = extract_context(text, match_data.begin(0), match_data.end(0))
      Rails.logger.debug { "EmojiReplacer: Detected emoji '#{emoji}' around: '#{context}'" }

      # Use caching
      img_tag = Rails.cache.fetch(cache_key(emoji), expires_in: 12.hours) do
        Rails.logger.debug { "EmojiReplacer: Cache miss for emoji '#{emoji}'. Building inline SVG." }
        build_inline_svg(emoji)
      end

      if img_tag
        Rails.logger.debug { "EmojiReplacer: Replacing emoji '#{emoji}' with img tag." }
        img_tag
      else
        Rails.logger.warn "EmojiReplacer: Failed to build img tag for emoji '#{emoji}'. Using original emoji."
        emoji
      end
    end
  end

  def cache_key(emoji)
    "emoji_replacer/v10/#{emoji}"
  end

  def build_inline_svg(emoji)
    codepoints = emoji.codepoints.reject { |cp| cp == 0xFE0F }.map { |cp| cp.to_s(16) }.join("-")
    Rails.logger.debug { "EmojiReplacer: Emoji codepoints for '#{emoji}': #{codepoints}" }

    begin
      svg_path_from_vite = ViteRuby.instance.manifest.path_for("emoji/#{codepoints}.svg", { type: :image })
    rescue ViteRuby::MissingEntrypointError
      Rails.logger.warn "EmojiReplacer: SVG manifest entry not found for emoji '#{emoji}' with codepoints '#{codepoints}'."
      return CGI.escapeHTML(emoji)
    end

    return CGI.escapeHTML(emoji) if svg_path_from_vite.blank?

    svg_content = read_vite_asset_content(svg_path_from_vite)

    if svg_content
      data_url = "data:image/svg+xml,#{ERB::Util.url_encode(svg_content)}"
      img_tag = %(<img src="#{data_url}" alt="#{emoji}" class="emoji" loading="eager" decoding="async" fetchpriority="low" draggable="false" tabindex="-1">)
      Rails.logger.debug { "EmojiReplacer: Built img tag with data URL for emoji '#{emoji}'" }
      img_tag
    else
      Rails.logger.warn "EmojiReplacer: SVG file not found or unreadable for emoji '#{emoji}'."
      CGI.escapeHTML(emoji)
    end
  rescue StandardError => e
    Rails.logger.error "EmojiReplacer: Failed to build inline SVG for emoji '#{emoji}': #{e.message}"
    CGI.escapeHTML(emoji)
  end

  # Helper to read asset content based on environment (copied from emoji_helper.rb)
  def read_vite_asset_content(path_from_manifest)
    return nil if path_from_manifest.blank?

    if Rails.env.development? || Rails.env.test?
      begin
        vite_uri = URI.join(ViteRuby.instance.config.public_base_url, path_from_manifest)
        response_body = Net::HTTP.get(vite_uri)
        response_body.presence
      rescue StandardError => e
        Rails.logger.error "EmojiReplacer: Error fetching asset from Vite dev server: #{e.message} for URI: #{vite_uri}"
        nil
      end
    else
      relative_path = path_from_manifest.sub(%r{^/?#{ViteRuby.instance.config.public_output_dir}/}, "")
      public_path = Rails.root.join("public", ViteRuby.instance.config.public_output_dir, relative_path)
      File.exist?(public_path) ? File.read(public_path) : nil
    end
  rescue StandardError => e
    Rails.logger.error "EmojiReplacer: Error reading Vite asset content for path '#{path_from_manifest}': #{e.message}"
    nil
  end

  def extract_context(text, match_start, match_end, window = 10)
    start_index = [ match_start - window, 0 ].max
    end_index = [ match_end + window, text.length ].min
    text[start_index...end_index]
  end
end

# ===== Emoji Processing Middleware Configuration =====
# Ensure this middleware runs before HTML compression but after general request processing.
# It's placed here rather than middleware.rb to keep the EmojiReplacer logic contained.
Rails.application.config.middleware.use EmojiReplacer, exclude_selectors: [
  "script", "style", "pre", "code", "textarea", "svg", "noscript", "template",
  ".no-emoji", "[data-no-emoji]", ".syntax-highlighted"
]
