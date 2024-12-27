class EmojiReplacer
  require "unicode"

  EMOJI_REGEX = /(\p{Emoji_Presentation}|\p{Emoji}\uFE0F)/

  def initialize(app)
    @app = app
  end

  def call(env)
    Rails.logger.debug "EmojiReplacer: Processing request for #{env['PATH_INFO']}"

    status, headers, body = @app.call(env)

    if headers["Content-Type"]&.include?("text/html")
      Rails.logger.debug "EmojiReplacer: Detected text/html content type"

      new_body = ""
      body.each do |part|
        new_part = part.gsub(EMOJI_REGEX) do |emoji|
          match_data = Regexp.last_match
          context = extract_context(part, match_data.begin(0), match_data.end(0))
          Rails.logger.debug "EmojiReplacer: Detected emoji '#{emoji}' around: '#{context}'"

          # Re-enable caching
          img_tag = Rails.cache.fetch(cache_key(emoji), expires_in: 12.hours) do
            Rails.logger.debug "EmojiReplacer: Cache miss for emoji '#{emoji}'. Building img tag."
            build_img_tag(emoji)
          end

          if img_tag
            Rails.logger.debug "EmojiReplacer: Replacing emoji '#{emoji}' with img tag."
            img_tag
          else
            Rails.logger.warn "EmojiReplacer: Failed to build img tag for emoji '#{emoji}'. Using original emoji."
            emoji
          end
        end

        new_body << new_part
      end

      # Update the body and Content-Length
      body = [ new_body ]
      headers["Content-Length"] = new_body.bytesize.to_s

      Rails.logger.debug "EmojiReplacer: Completed emoji replacement. Updated Content-Length to #{new_body.bytesize}."
    else
      Rails.logger.debug "EmojiReplacer: Skipping emoji replacement. Content-Type is not text/html."
    end

    # Return the modified response
    [ status, headers, body ]
  rescue => e
    Rails.logger.error "EmojiReplacer: Error processing request: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    [ 500, { "Content-Type" => "text/plain" }, [ "Internal Server Error" ] ]
  end

  private

  # Generates a unique cache key for each emoji
  def cache_key(emoji)
    "emoji_replacer/#{emoji}"
  end

  # Builds the <img> tag for a given emoji
  def build_img_tag(emoji)
    # Exclude variation selectors (e.g., FE0F)
    codepoints = emoji.codepoints.reject { |cp| cp == 0xFE0F }.map { |cp| cp.to_s(16) }.join("-")
    Rails.logger.debug "EmojiReplacer: Emoji codepoints for '#{emoji}': #{codepoints}"

    svg_path = ViteRuby.instance.manifest.path_for("emoji/#{codepoints}.svg")
    Rails.logger.debug "EmojiReplacer: Resolved SVG path for emoji '#{emoji}': #{svg_path}"

    if svg_path.nil? || svg_path.empty?
      Rails.logger.warn "EmojiReplacer: SVG path not found for emoji '#{emoji}' with codepoints '#{codepoints}'."
      return emoji
    end

    img_tag = %Q(<img src="#{svg_path}" alt="#{emoji}" class="emoji" loading="lazy" decoding="async" fetchpriority="low" draggable="false" tabindex="”-1”">)
    Rails.logger.debug "EmojiReplacer: Built img tag for emoji '#{emoji}': #{img_tag}"
    img_tag
  rescue => e
    Rails.logger.error "EmojiReplacer: Failed to build img tag for emoji '#{emoji}': #{e.message}"
    emoji
  end

  # Extracts a substring around the emoji for context
  def extract_context(text, match_start, match_end, window = 10)
    start_index = [ match_start - window, 0 ].max
    end_index = [ match_end + window, text.length ].min
    text[start_index...end_index]
  end
end
