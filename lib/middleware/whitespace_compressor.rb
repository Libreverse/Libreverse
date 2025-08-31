# frozen_string_literal: true

require "re2"
require "json"
require "minify_html"

class WhitespaceCompressor
  def initialize(app)
    @app = app
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
