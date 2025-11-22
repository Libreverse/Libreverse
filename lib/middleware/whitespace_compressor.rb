# frozen_string_literal: true
# shareable_constant_value: literal

require "json"
require "htmlcompressor"
require "digest/sha1"
require "nokogiri"

class WhitespaceCompressor
  COMPRESSOR_CONFIG = {
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
  }.freeze

  SRC_DOC_COMPRESSOR_CONFIG = COMPRESSOR_CONFIG.merge(
    compress_css: true,
    compress_javascript: true
  ).freeze

  def initialize(app)
    @app = app
    # NOTE: We don't pre-split or exclude tags like <pre>, <textarea>, or <script>.
    # htmlcompressor is spec-aware and preserves content of rawtext/RCDATA elements safely,
    # so an explicit "preserve" regex is unnecessary and can introduce edge-case bugs.
  end

  def call(env)
    status, headers, body = @app.call(env)
    return [status, headers, body] unless html_response?(headers)

    log_debug("WhitespaceCompressor: Processing HTML response")

    html = assemble_html(body)
    return [status, headers, body] if html.empty?

    html = process_html_with_cache(html)

    log_debug("WhitespaceCompressor: Minified HTML length: #{html.length}")

    update_headers(headers, html)
    [status, headers, [html]]
  end

  private

  def html_response?(headers)
    headers["Content-Type"]&.include?("text/html")
  end

  def assemble_html(body)
    return "" unless body.respond_to?(:each)

    chunks = []
    body.each { |chunk| chunks << chunk.to_s.encode("UTF-8", invalid: :replace, undef: :replace) }
    html = chunks.join
    body.close if body.respond_to?(:close)
    log_debug("WhitespaceCompressor: Original HTML length: #{html.length}")
    html
  end

  def process_html_with_cache(html)
    cache_key = "wc_html:#{::Digest::SHA1.hexdigest(html)}"
    cache = defined?(Rails) && Rails.respond_to?(:cache) ? Rails.cache : nil
    cache&.fetch(cache_key, expires_in: 1.hour) do
      process_html(html)
    end || process_html(html)
  end

  def process_html(html)
    processed = minify_jsonld_scripts_with_nokogiri(html)
    processed = minify_srcdoc_iframes_with_nokogiri(processed)
    HtmlCompressor::Compressor.new(COMPRESSOR_CONFIG).compress(processed)
  end

  def update_headers(headers, html)
    headers["Content-Length"] = html.bytesize.to_s
    headers.delete("Content-Encoding")
  end

  def log_debug(message)
    Rails.logger.debug(message) if defined?(Rails)
  end

  def log_warn(message)
    Rails.logger.warn(message) if defined?(Rails)
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
    log_warn("WhitespaceCompressor: Failed JSON-LD minify: #{e.class}: #{e.message}")
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
        minified_content = HtmlCompressor::Compressor.new(SRC_DOC_COMPRESSOR_CONFIG).compress(content)
        node["srcdoc"] = minified_content
      rescue StandardError => e
        log_warn("WhitespaceCompressor: Failed to minify srcdoc: #{e.message}")
      end
    end
    doc.to_html
  rescue StandardError => e
    log_warn("WhitespaceCompressor: Failed srcdoc pass: #{e.class}: #{e.message}")
    html
  end
end
