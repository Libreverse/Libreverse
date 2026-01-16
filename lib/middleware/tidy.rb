# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

require "open3"
require "htmlcompressor"
#
# TidyMiddleware — cleans/repairs HTML via tidy CLI. This keeps the middleware
# focused on the tidy executable instead of chaining additional post-processing
# passes, reducing complexity while still ensuring well-formed output.

class TidyMiddleware
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

  def initialize(app)
    @app = app
    @compressor = HtmlCompressor::Compressor.new(COMPRESSOR_OPTIONS)
  end

  def call(env)
    status, headers, response = @app.call(env)

    if headers["Content-Type"]&.include?("text/html")
      # Assemble full body
      body = case response
      when String then response
      when Array then response.join
      when Enumerable then response.inject("") { |acc, part| acc << part }
      else response.to_s
      end

      # First pass: repair/clean with conservative Tidy options (your original config, fixed)
      tidy_cmd = [
        "tidy",
        "-q", # quiet
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

      # Final pass: HTML compression for whitespace/tags
      compressed_html = @compressor.compress(cleaned_html)
      response_body = compressed_html.presence || cleaned_html

      # Replace response body with tidy+compressed output
      response = [ response_body ]
      headers["Content-Length"] = response_body.bytesize.to_s if headers["Content-Length"]
    end

    [ status, headers, response ]
  end
end
