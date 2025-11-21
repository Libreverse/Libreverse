# frozen_string_literal: true
# shareable_constant_value: literal

require "json"
require "htmlcompressor"
require "digest/sha1"
require "nokogiri"

class WhitespaceCompressor
  def initialize(app)
    @app = app
    # NOTE: We don't pre-split or exclude tags like <pre>, <textarea>, or <script>.
    # htmlcompressor is spec-aware and preserves content of rawtext/RCDATA elements safely,
    # so an explicit "preserve" regex is unnecessary and can introduce edge-case bugs.
  end

  def call(env)
    status, headers, body = @app.call(env)
    return [ status, headers, body ] unless headers["Content-Type"]&.include?("text/html")

    Rails.logger.debug "WhitespaceCompressor: Processing HTML response" if defined?(Rails)

    # Step 1: Assemble HTML efficiently
    return [ status, headers, body ] unless body.respond_to?(:each)

    chunks = []
    body.each { |chunk| chunks << chunk.to_s.encode("UTF-8", invalid: :replace, undef: :replace) }
    html = chunks.join
    # We replace the body, so close the original to avoid leaks
    body.close if body.respond_to?(:close)

    Rails.logger.debug "WhitespaceCompressor: Original HTML length: #{html.length}" if defined?(Rails)

    # Caching: Use Rails.cache to store processed HTML based on SHA1 hash of original
    # This saves unnecessary work for repeated identical responses (e.g., static pages)
    unless html.empty?
      cache_key = "wc_html:#{::Digest::SHA1.hexdigest(html)}"
      html = (defined?(Rails) && Rails.respond_to?(:cache) ? Rails.cache : nil)&.fetch(cache_key, expires_in: 1.hour) do
        # Step 1.5: Minify JSON-LD scripts before other processing (Nokogiri-based)
        processed = minify_jsonld_scripts_with_nokogiri(html)

        # Step 1.6: Minify iframe srcdoc content (Nokogiri-based)
        processed = minify_srcdoc_iframes_with_nokogiri(processed)

        # Step 2: Apply htmlcompressor for efficient whitespace and comment removal
        # Configure htmlcompressor options for optimal minification
        minify_config = {
          enabled: true,
          remove_spaces_inside_tags: true,
          remove_multi_spaces: true,
          remove_comments: true,
          remove_intertag_spaces: false,
          remove_quotes: true,
          compress_css: false,
          compress_javascript: false,
          simple_doctype: true,
          remove_script_attributes: false,
          remove_style_attributes: false,
          remove_link_attributes: false,
          remove_form_attributes: false,
          remove_input_attributes: true,
          remove_javascript_protocol: false,
          remove_http_protocol: false,
          remove_https_protocol: false,
          preserve_line_breaks: false,
          simple_boolean_attributes: false,
          compress_js_templates: false
        }

  # Always apply htmlcompressor for optimal compression - it's more effective than HAML's whitespace removal
  HtmlCompressor::Compressor.new(minify_config).compress(processed)
      end || begin
        # Fallback path when Rails.cache is unavailable
        processed = minify_jsonld_scripts_with_nokogiri(html)
        processed = minify_srcdoc_iframes_with_nokogiri(processed)
        HtmlCompressor::Compressor.new({
                                         enabled: true,
                                         remove_spaces_inside_tags: true,
                                         remove_multi_spaces: true,
                                         remove_comments: true,
                                         remove_intertag_spaces: false,
                                         remove_quotes: true,
                                         compress_css: false,
                                         compress_javascript: false,
                                         simple_doctype: true,
                                         remove_script_attributes: false,
                                         remove_style_attributes: false,
                                         remove_link_attributes: false,
                                         remove_form_attributes: false,
                                         remove_input_attributes: true,
                                         remove_javascript_protocol: false,
                                         remove_http_protocol: false,
                                         remove_https_protocol: false,
                                         preserve_line_breaks: false,
                                         simple_boolean_attributes: false,
                                         compress_js_templates: false
                                       }).compress(processed)
      end
    end

    Rails.logger.debug "WhitespaceCompressor: Minified HTML length: #{html.length}" if defined?(Rails)

    # Update headers before returning
    new_headers = headers.dup
    new_headers["Content-Length"] = html.bytesize.to_s
    new_headers.delete("Content-Encoding")
    [ status, new_headers, [ html ] ]
  end

  # Minify JSON-LD scripts by parsing and re-serializing JSON content (no regex lookaheads/backrefs)
  def minify_jsonld_scripts_with_nokogiri(html)
    doc = Nokogiri::HTML4.parse(html)
    doc.css("script").each do |node|
      type = node["type"]
      next unless type && type.to_s.downcase.strip == "application/ld+json"

      raw = node.children.to_s
      # Strip CDATA if present
      cleaned = raw.sub(/^\s*<!\[CDATA\[/, "").sub(/\]\]>\s*$/, "").strip
      next unless cleaned.start_with?("{", "[")

      begin
        minified = JSON.generate(JSON.parse(cleaned))
        node.children = Nokogiri::XML::Text.new(minified, doc)
      rescue JSON::ParserError
        # ignore invalid JSON
      end
    end
    doc.to_html
  rescue StandardError => e
    Rails.logger.warn "WhitespaceCompressor: Failed JSON-LD minify: #{e.class}: #{e.message}" if defined?(Rails)
    html
  end

  # Minify inline HTML in iframe[srcdoc] attributes using Nokogiri
  def minify_srcdoc_iframes_with_nokogiri(html)
    doc = Nokogiri::HTML4.parse(html)
    doc.css("iframe[srcdoc]").each do |node|
      content = node["srcdoc"].to_s
      next if content.strip.empty?
      next unless content.lstrip.start_with?("<")

      begin
        minified_content = HtmlCompressor::Compressor.new({
                                                            enabled: true,
                                                            remove_spaces_inside_tags: true,
                                                            remove_multi_spaces: true,
                                                            remove_comments: true,
                                                            remove_intertag_spaces: false,
                                                            remove_quotes: true,
                                                            compress_css: true,
                                                            compress_javascript: true,
                                                            simple_doctype: true,
                                                            remove_script_attributes: false,
                                                            remove_style_attributes: false,
                                                            remove_link_attributes: false,
                                                            remove_form_attributes: false,
                                                            remove_input_attributes: true,
                                                            remove_javascript_protocol: false,
                                                            remove_http_protocol: false,
                                                            remove_https_protocol: false,
                                                            preserve_line_breaks: false,
                                                            simple_boolean_attributes: false,
                                                            compress_js_templates: false
                                                          }).compress(content)
        node["srcdoc"] = minified_content
      rescue StandardError => e
        Rails.logger.warn "WhitespaceCompressor: Failed to minify srcdoc: #{e.message}" if defined?(Rails)
      end
    end
    doc.to_html
  rescue StandardError => e
    Rails.logger.warn "WhitespaceCompressor: Failed srcdoc pass: #{e.class}: #{e.message}" if defined?(Rails)
    html
  end
end
