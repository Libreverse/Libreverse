# frozen_string_literal: true

require "re2"
require "json"
require "minify_html"
require "digest/sha1"

class WhitespaceCompressor
  def initialize(app)
    @app = app
    # Compile RE2 pattern for newline removal - fixed for ReDoS prevention
    @pattern_newlines = RE2::Regexp.new('\n+', log_errors: false)
    # Preserve pattern for splitting (using Ruby regex for split compatibility)
    @preserve_pattern = %r{(<textarea>(?:[^<]|<(?!/textarea>))*</textarea>|<pre>(?:[^<]|<(?!/pre>))*</pre>|<script>(?:[^<]|<(?!/script>))*</script>|<iframe>(?:[^<]|<(?!/iframe>))*</iframe>)}
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

    # Debug: Log original HTML length
    Rails.logger.debug "WhitespaceCompressor: Original HTML length: #{html.length}"

    # Caching: Use Rails.cache to store processed HTML based on SHA1 hash of original
    # This saves unnecessary work for repeated identical responses (e.g., static pages)
    unless html.empty?
      cache_key = "wc_html:#{::Digest::SHA1.hexdigest(html)}"
      html = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        # Step 1.5: Minify JSON-LD scripts before other processing
        html = minify_jsonld_scripts(html)

        # Step 2: Apply minify_html for efficient whitespace and comment removal
        # Configure minify_html options for optimal minification
        minify_config = {
          allow_noncompliant_unquoted_attribute_values: true,  # Safe for modern browsers
          allow_optimal_entities: true,                        # Safe optimizations
          allow_removing_spaces_between_attributes: true,      # Safe space removal
          keep_closing_tags: false,                            # Omit unnecessary closing tags
          keep_comments: false,                                # Remove all comments
          keep_html_and_head_opening_tags: false,              # Omit if no attributes
          keep_input_type_text_attr: false,                    # Omit default type=text
          keep_ssi_comments: false,                            # Remove SSI comments
          minify_css: false, # CSS already minified before inclusion
          minify_doctype: true,                                # Minify DOCTYPE
          minify_js: false,                                    # JS already minified before inclusion
          preserve_brace_template_syntax: false,               # Don't preserve unless using {{ }} templates
          preserve_chevron_percent_template_syntax: false,     # Don't preserve unless using <% %> templates
          remove_bangs: true,                                  # Remove bangs
          remove_processing_instructions: true                 # Remove processing instructions
        }

        # Always apply minify_html for optimal compression - it's more effective than HAML's whitespace removal
        html = minify_html(html, minify_config)

        # Step 2.5: Quick RE2 pass to remove remaining newlines (\n+) in non-preserved parts
        parts = html.split(@preserve_pattern, -1)
        i = 0
        len = parts.length
        while i < len
          unless i.odd?
            part = parts[i]
            parts[i] = RE2.GlobalReplace(part, @pattern_newlines, "")
          end
          i += 1
        end
        html = parts.join

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
    # Enhanced pattern to match JSON-LD scripts with various formats - fixed for ReDoS prevention
    html.gsub(%r{<script[^>]*type=["']application/ld\+json["'][^>]*>((?:[^<]|<(?!/script>))*)</script>}i) do
      full_match = Regexp.last_match(0)
      json_content = Regexp.last_match(1)
      script_opening = full_match[/<script[^>]*>/i]
      script_closing = "</script>"

      begin
        # Remove CDATA wrapper if present
        clean_content = json_content.gsub(/^\s*<!\[CDATA\[(.*?)\]\]>\s*$/m, '\1')

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
end