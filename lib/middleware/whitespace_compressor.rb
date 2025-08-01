# frozen_string_literal: true

require "re2"
require "json"

class WhitespaceCompressor
  def initialize(app)
    @app = app
    # Compile RE2 patterns once during initialization - fixed for ReDoS prevention
    @preserve_pattern = %r{(<textarea>(?:[^<]|<(?!/textarea>))*</textarea>|<pre>(?:[^<]|<(?!/pre>))*</pre>|<script>(?:[^<]|<(?!/script>))*</script>|<iframe>(?:[^<]|<(?!/iframe>))*</iframe>)}
    @pattern_comments = RE2::Regexp.new('<!--[\s\S]*?-->', log_errors: false)

    # HAML whitespace optimization patterns - only used for non-HAML content
    # HAML's remove_whitespace: true already handles most of these efficiently
    @pattern_between_tags = RE2::Regexp.new('>\s+<', log_errors: false)
    @pattern_spaces = RE2::Regexp.new('\s{2,}', log_errors: false)
    @pattern_attr_eq = RE2::Regexp.new('(<[^>]*?)\s*=\s*([^>]*>)', log_errors: false)
    @pattern_attr_sp = RE2::Regexp.new('(<[^>]*?)\s{2,}([^>]*>)', log_errors: false)

    # Detect HAML-generated content by checking if HAML template options are enabled
    @haml_whitespace_enabled = defined?(Haml::Template) &&
                               Haml::Template.options[:remove_whitespace] == true
  end

  def call(env)
    status, headers, body = @app.call(env)
    return [ status, headers, body ] unless headers["Content-Type"]&.include?("text/html")

    # Step 1: Assemble HTML efficiently
    chunks = []
    body.each { |chunk| chunks << chunk.encode("UTF-8", invalid: :replace, undef: :replace) }
    html = chunks.join

    # Step 1.5: Minify JSON-LD scripts before other processing
    html = minify_jsonld_scripts(html)

    # Step 2: Split into preserve and non-preserve parts
    parts = html.split(@preserve_pattern, -1)

    # Step 3: Process only non-preserve parts
    i = 0
    len = parts.length
    while i < len
      unless i.odd?
        part = parts[i]

        # Always remove HTML comments (HAML doesn't handle this)
        part = RE2.GlobalReplace(part, @pattern_comments, "")

        # Apply whitespace compression only if HAML whitespace removal is disabled
        # or if this appears to be non-HAML generated content
        unless @haml_whitespace_enabled && haml_generated_content?(part)
          part = RE2.GlobalReplace(part, @pattern_between_tags, "><")
          part = RE2.GlobalReplace(part, @pattern_spaces, " ")
          part = RE2.GlobalReplace(part, @pattern_attr_eq, '\1=\2')
          part = RE2.GlobalReplace(part, @pattern_attr_sp, '\1 \2')
        end

        parts[i] = part
      end
      i += 1
    end

    # Step 4: Reassemble HTML
    html = parts.join

    # Step 5: Update headers and return response
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

  # Heuristic to detect if content was likely generated by HAML
  # HAML-generated HTML tends to have very clean formatting already
  def haml_generated_content?(html_part)
    return false if html_part.strip.empty?

    # Simple heuristics for HAML-generated content:
    # 1. No excessive whitespace between tags (HAML handles this)
    # 2. Clean attribute formatting (HAML generates clean attributes)
    # 3. Minimal redundant spaces

    sample_size = [ html_part.length, 500 ].min
    sample = html_part[0, sample_size]

    # Count problematic patterns that HAML would have already cleaned up
    excessive_whitespace = sample.scan(/>\s{2,}</).length
    messy_attributes = sample.scan(/\s{2,}=|\s*=\s{2,}/).length

    # If we find very few problematic patterns, likely HAML-generated
    (excessive_whitespace + messy_attributes) < 3
  end
end
