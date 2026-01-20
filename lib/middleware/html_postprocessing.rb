# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

require "open3"
require "htmlcompressor"
require "erb"  # For ERB::Util.html_escape
require "unicode"
require "nokogiri"
require "digest/sha1"
require "set"
require "auto_html"

#
# HtmlPostprocessingMiddleware — runs post-processing passes over HTML.
# focused on the tidy executable instead of chaining additional post-processing
# passes, reducing complexity while still ensuring well-formed output.

class HtmlPostprocessingMiddleware
  COMPRESSOR_OPTIONS = {
    enabled: true,
    remove_multi_spaces: true,
    remove_comments: true,
    remove_intertag_spaces: true,
    remove_quotes: false,
    compress_css: false,
    compress_javascript: false,
    simple_doctype: false,
    remove_script_attributes: false,
    remove_style_attributes: false,
    remove_link_attributes: false,
    remove_form_attributes: false,
    remove_input_attributes: false,
    remove_javascript_protocol: false,
    remove_http_protocol: false,
    remove_https_protocol: false,
    preserve_line_breaks: false,
    simple_boolean_attributes: false
  }.freeze

  DEFAULT_EXCLUDE_SELECTORS = %w[script style pre code textarea svg noscript].freeze

  EXCLUDED_PATHS = [
    %r{^/rails/active_storage/},
    %r{^/active_storage/}
  ].freeze

  def initialize(app, options = {})
    @app = app
    @exclude_selectors = options[:exclude_selectors] || DEFAULT_EXCLUDE_SELECTORS
    @compressor = HtmlCompressor::Compressor.new(COMPRESSOR_OPTIONS)
  end

  def call(env)
    path = env["PATH_INFO"]
    return @app.call(env) if path_excluded?(path)

    return @app.call(env) if request_is_binary?(env)

    status, headers, response = @app.call(env)

    if headers["Content-Type"]&.include?("text/html")
      body = case response
      when String then response
      when Array then response.join
      when Enumerable then response.inject("") { |acc, part| acc << part }
      else response.to_s
      end

      cache_key = "html_post:#{::Digest::SHA1.hexdigest(body)}"
      body = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        body = AutoHtml.auto_html(body) do
          emoji
        end
        if @exclude_selectors.any? && body.include?("<html")
          process_emojis_with_nokogiri(body)
        else
          replace_emojis(body)
        end
      end

      tidy_cmd = [
        "tidy",
        "-q",
        "-utf8",
        "-wrap", "0",
        "--clean", "no",
        "--drop-proprietary-attributes", "no",
        "--force-output", "yes",
        "--show-warnings", "no",
        "--tidy-mark", "yes",
        "--output-html", "yes",
        "--output-xhtml", "no",
        "--output-xml", "no",
        "--hide-comments", "yes",
        "--bare", "no",
        "--logical-emphasis", "yes",
        "--drop-empty-paras", "yes",
        "--fix-bad-comments", "yes",
        "--break-before-br", "no",
        "--numeric-entities", "yes",
        "--quote-marks", "no",
        "--quote-nbsp", "no",
        "--quote-ampersand", "no",
        "--wrap-attributes", "no",
        "--wrap-script-literals", "no",
        "--wrap-sections", "no",
        "--wrap-asp", "no",
        "--wrap-jste", "no",
        "--wrap-php", "no",
        "--fix-backslash", "yes",
        "--indent-attributes", "no",
        "--assume-xml-procins", "yes",
        "--add-xml-space", "yes",
        "--enclose-text", "no",
        "--enclose-block-text", "no",
        "--gnu-emacs", "no",
        "--literal-attributes", "yes",
        "--show-body-only", "no",
        "--fix-uri", "yes",
        "--lower-literals", "no",
        "--indent-cdata", "no",
        "--ascii-chars", "yes",
        "--join-classes", "no",
        "--join-styles", "no",
        "--escape-cdata", "no",
        "--ncr", "no",
        "--replace-color", "no",
        "--vertical-space", "no",
        "--punctuation-wrap", "no",
        "--merge-divs", "auto",
        "--decorate-inferred-ul", "yes",
        "--drop-empty-elements", "yes",
        "--merge-spans", "auto",
        "--preserve-entities", "no",
        "--anchor-as-name", "yes",
        "--coerce-endtags", "yes",
        "--escape-scripts", "yes",
        "--fix-style-tags", "yes",
        "--repeated-attributes", "keep-last",
        "--strict-tags-attributes", "no",
        "--merge-emphasis", "yes"
      ]

      cleaned_html, stderr_str, tidy_status = Open3.capture3(*tidy_cmd, stdin_data: body)

      raise "Tidy CLI produced no output (exit=#{tidy_status.exitstatus}): #{stderr_str}" if cleaned_html.nil? || cleaned_html.strip.empty?

      if stderr_str && !stderr_str.strip.empty?
        fatal_patterns = [ /\bError\b/i, /not a file/i, /unknown option/i, /invalid/i, /fatal/i ]
        raise "Tidy CLI error (exit=#{tidy_status.exitstatus}): #{stderr_str}" if stderr_str.lines.any? { |l| fatal_patterns.any? { |pat| l =~ pat } }

        warn "Tidy CLI warnings: #{stderr_str}" if defined?(Rails)
      end

      escaped_html = ERB::Util.html_escape(cleaned_html)

      compressed_html = @compressor.compress(escaped_html)
      response_body = compressed_html.presence || escaped_html

      response = [ response_body ]
      headers["Content-Length"] = response_body.bytesize.to_s if headers["Content-Length"]
    end

    [ status, headers, response ]
  end

  private

  def path_excluded?(path)
    EXCLUDED_PATHS.any? { |pattern| path.match?(pattern) }
  end

  def request_is_binary?(env)
    return true if env["CONTENT_TYPE"]&.start_with?("multipart/form-data")
    return true if env["HTTP_ACCEPT"]&.include?("application/octet-stream")
    return true if env["HTTP_CONTENT_DISPOSITION"]&.include?("attachment")
    return true if env["CONTENT_LENGTH"] && env["CONTENT_LENGTH"].to_i > 1_000_000

    false
  end

  def require_emoji_renderer
    return if defined?(Emoji::Renderer)

    require Rails.root.join("lib/emoji/renderer").to_s
  end

  def process_emojis_with_nokogiri(html)
    if html.blank?
      Rails.logger.warn "EmojiReplacer: Skipping processing of invalid HTML"
      return html
    end

    doc = Nokogiri::HTML4.parse(html)

    exclude_nodes = Set.new
    @exclude_selectors.each do |selector|
      doc.css(selector).each do |node|
        exclude_nodes.add(node)
      end
    end

    doc.traverse do |node|
      next unless node.text? && !within_excluded_node?(node, exclude_nodes)

      replaced_content = replace_emojis_with_nodes(node.content)

      if replaced_content != node.content
        fragment = Nokogiri::HTML4.fragment(replaced_content)
        node.replace(fragment)
      end
    end

    doc.to_html
  rescue Nokogiri::XML::SyntaxError => e
    Rails.logger.error "EmojiReplacer: HTML parsing error: #{e.message}"
    html
  rescue StandardError => e
    Rails.logger.error "EmojiReplacer: Processing error: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    html
  end

  def replace_emojis_with_nodes(text)
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

  def ensure_utf8(str)
    return str if str.encoding == Encoding::UTF_8

    str.force_encoding(Encoding::UTF_8)
    return str if str.valid_encoding?

    str.encode(Encoding::UTF_8, invalid: :replace, undef: :replace)
  rescue StandardError
    str
  end

  def replace_emojis(text)
    text = ensure_utf8(text)
    require_emoji_renderer
    Emoji::Renderer.replace(text)
  end
end
