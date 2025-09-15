# frozen_string_literal: true

require "json"
require "minify_html"
require "digest/sha1"
require "re2"

class WhitespaceCompressor
  def initialize(app)
    @app = app
    # NOTE: We don't pre-split or exclude tags like <pre>, <textarea>, or <script>.
    # minify_html is spec-aware and preserves content of rawtext/RCDATA elements safely,
    # so an explicit "preserve" regex is unnecessary and can introduce edge-case bugs.
  end

  def call(env)
    status, headers, body = @app.call(env)
    return [ status, headers, body ] unless headers["Content-Type"]&.include?("text/html")

    # Debug: Log that middleware is running
    Rails.logger.debug "WhitespaceCompressor: Processing HTML response"

    # Step 1: Assemble HTML efficiently
    chunks = []
    body.each { |chunk| chunks << chunk.encode("UTF-8", invalid: :replace, undef: :replace) }
    html = chunks.join
    # We replace the body, so close the original to avoid leaks
    body.close if body.respond_to?(:close)

    # Debug: Log original HTML length
    Rails.logger.debug "WhitespaceCompressor: Original HTML length: #{html.length}"

    # Caching: Use Rails.cache to store processed HTML based on SHA1 hash of original
    # This saves unnecessary work for repeated identical responses (e.g., static pages)
    unless html.empty?
      cache_key = "wc_html:#{::Digest::SHA1.hexdigest(html)}"
      html = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        # Step 1.5: Minify JSON-LD scripts before other processing
        html = minify_jsonld_scripts(html)

        # Step 1.6: Minify iframe srcdoc content
        html = minify_srcdoc_iframes(html)

        # Step 2: Apply minify_html for efficient whitespace and comment removal
        # Configure minify_html options for optimal minification
        minify_config = {
          allow_noncompliant_unquoted_attribute_values: true, # Safe for modern browsers
          allow_optimal_entities: true,                        # Safe optimizations
          allow_removing_spaces_between_attributes: true,      # Safe space removal
          keep_closing_tags: false,                            # Omit unnecessary closing tags
          keep_comments: false,                                # Remove all comments
          keep_html_and_head_opening_tags: false,              # Omit if no attributes
          keep_input_type_text_attr: false,                    # Omit default type=text
          keep_ssi_comments: false,                            # Remove SSI comments
          minify_css: false,                                   # Skip since already minified
          minify_doctype: true,                                # Minify DOCTYPE
          minify_js: false,                                    # Skip since already minified
          preserve_brace_template_syntax: false,               # Don't preserve unless using {{ }} templates
          preserve_chevron_percent_template_syntax: false,     # Don't preserve unless using <% %> templates
          remove_bangs: true,                                  # Remove bangs
          remove_processing_instructions: true                 # Remove processing instructions
        }

        # Always apply minify_html for optimal compression - it's more effective than HAML's whitespace removal
        html = MinifyHtml.minify(html, minify_config)

        # Return the fully processed HTML
        html
      end
    end

    # Debug: Log minified HTML length
    Rails.logger.debug "WhitespaceCompressor: Minified HTML length: #{html.length}"

    # Step 3: Update headers and return response
    headers["Content-Length"] = html.bytesize.to_s
    headers.delete("Content-Encoding")
    [ status, headers, [ html ] ]
  end

  private

  # Minify JSON-LD scripts by parsing and re-serializing JSON content
  def minify_jsonld_scripts(html)
    jsonld_pattern = RE2::Regexp.new('<script[^>]*type=["\']application/ld\+json["\'][^>]*>((?:[^<]|<(?!/script>))*)</script>', options: { casefold: true })
    # Enhanced pattern to match JSON-LD scripts with various formats - fixed for ReDoS prevention
    html.gsub(jsonld_pattern) do
      full_match = Regexp.last_match(0)
      json_content = Regexp.last_match(1)
      script_opening_pattern = RE2::Regexp.new("<script[^>]*>", options: { casefold: true })
      script_opening = full_match[script_opening_pattern]
      script_closing = "</script>"

      begin
        # Remove CDATA wrapper if present
        cdata_pattern = RE2::Regexp.new('^\s*<!\[CDATA\[(.*?)\]\]>\s*$', options: { multiline: true })
        clean_content = json_content.gsub(cdata_pattern, '\1')

        # Clean up the content - remove extra whitespace but preserve the JSON structure
        clean_content = clean_content.strip

        # Only process if it looks like JSON (starts with { or [)
        if clean_content.start_with?("{", "[")
          # Parse and re-serialize JSON to remove whitespace
          parsed_json = JSON.parse(clean_content)
          minified_json = JSON.generate(parsed_json)

          # Return the complete script tag with minified JSON
          "#{script_opening}#{minified_json}#{script_closing}"
        else
          # If it doesn't look like JSON, return original
          full_match
        end
      rescue JSON::ParserError
        # If JSON is invalid, return original script tag unchanged
        full_match
      end
    end
  end

  # Minify inline HTML in iframe srcdoc attributes
  def minify_srcdoc_iframes(html)
    srcdoc_pattern = RE2::Regexp.new('(<iframe[^>]*srcdoc=(["\'])(.*?)\2([^>]*>))', options: { casefold: true, multiline: true })
    # Pattern to match iframe tags with srcdoc, handling double or single quotes safely
    # Assumes srcdoc content uses entity-escaped quotes (&quot; or &#39;) if needed
    html.gsub(srcdoc_pattern) do
      prefix = ::Regexp.last_match(1)       # Everything up to srcdoc=
      quote = ::Regexp.last_match(2)        # The opening quote (" or ')
      content = ::Regexp.last_match(3)      # The inline HTML content
      suffix = ::Regexp.last_match(4)       # The rest of the tag after the closing quote

      begin
        # Only process if content looks like HTML (non-empty and starts with <)
        if content.strip.start_with?("<") && !content.empty?
          # Config for srcdoc: only enable JS and CSS minification, preserve HTML structure
          minify_config_srcdoc = {
            allow_noncompliant_unquoted_attribute_values: false,
            allow_optimal_entities: false,
            allow_removing_spaces_between_attributes: false,
            keep_closing_tags: true,
            keep_comments: true,
            keep_html_and_head_opening_tags: true,
            keep_input_type_text_attr: true,
            keep_ssi_comments: true,
            minify_css: true,
            minify_doctype: false,
            minify_js: true,
            preserve_brace_template_syntax: true,
            preserve_chevron_percent_template_syntax: true,
            remove_bangs: false,
            remove_processing_instructions: false
          }

          # Minify the srcdoc content with the targeted config
          minified_content = MinifyHtml.minify(content, minify_config_srcdoc)

          # Reassemble the tag with minified srcdoc
          "#{prefix}#{quote}#{minified_content}#{quote}#{suffix}"
        else
          # If not valid HTML-like, return original match
          ::Regexp.last_match(0)
        end
      rescue StandardError => e
        # If minification fails (e.g., invalid HTML), log and return original
        Rails.logger.warn "WhitespaceCompressor: Failed to minify srcdoc: #{e.message}"
        ::Regexp.last_match(0)
      end
    end
  end
end
