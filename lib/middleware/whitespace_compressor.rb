# frozen_string_literal: true

require "re2"
require "rack"

class WhitespaceCompressor
  def initialize(app)
    @app = app
    # Compile the RE2 regex once during initialization
    @regex = RE2::Regexp.new('\\s{2,}', log_errors: false)
  end

  def call(env)
    status, headers, body = @app.call(env)
    # Log entry into middleware
    Rails.logger.info("[WhitespaceCompressor] Received request #{env['REQUEST_METHOD']} #{env['PATH_INFO']}, Content-Type: #{headers['Content-Type']}") if defined?(Rails) && Rails.respond_to?(:logger)

    # Only process if the response is HTML
    if headers["Content-Type"]&.include?("text/html")
      # Log that we're processing HTML
      Rails.logger.info("[WhitespaceCompressor] Processing HTML response") if defined?(Rails) && Rails.logger
      # Step 0: Assemble full body into a UTF-8 string
      html = "".dup
      body.each { |chunk| html << chunk.encode("UTF-8", invalid: :replace, undef: :replace) }
      orig_size = html.bytesize

      # Step 1: Remove HTML comments globally
      pattern_comments = RE2::Regexp.new('<!--[\s\S]*?-->', log_errors: false)
      loop do
        new_html = RE2.Replace(html, pattern_comments, "")
        break if new_html == html

        html = new_html
      end

      # Step 2: Preserve space-sensitive tags via placeholders
      preserves = []
      pattern_preserve = RE2::Regexp.new('(<textarea>[\s\S]*?<\/textarea>|<pre>[\s\S]*?<\/pre>|<script>[\s\S]*?<\/script>|<iframe>[\s\S]*?<\/iframe>)', log_errors: false)
      while pattern_preserve.match?(html)
        m = pattern_preserve.match(html)
        tag_str = m[0]
        placeholder = "{__WP#{preserves.size}}"
        preserves << tag_str
        html = RE2.Replace(html, pattern_preserve, placeholder)
      end

      # Step 3a: Remove spaces around '=' in tags repeatedly
      pattern_attr_eq = RE2::Regexp.new('(<[^>]*?)\s*=\s*([^>]*>)', log_errors: false)
      loop do
        new_html = RE2.Replace(html, pattern_attr_eq, '\\1=\\2')
        break if new_html == html

        html = new_html
      end

      # Step 3b: Collapse multiple spaces within tags to one
      pattern_attr_sp = RE2::Regexp.new('(<[^>]*?)\s{2,}([^>]*>)', log_errors: false)
      loop do
        new_html = RE2.Replace(html, pattern_attr_sp, '\\1 \\2')
        break if new_html == html

        html = new_html
      end

      # Step 4: Remove whitespace between tags
      pattern_between = RE2::Regexp.new('>\s+<', log_errors: false)
      loop do
        new_html = RE2.Replace(html, pattern_between, "><")
        break if new_html == html

        html = new_html
      end

      # Step 5: Collapse multiple spaces and line breaks globally
      pattern_spaces = RE2::Regexp.new('\s{2,}', log_errors: false)
      loop do
        new_html = RE2.Replace(html, pattern_spaces, " ")
        break if new_html == html

        html = new_html
      end

      # Step 6: Restore preserved tag contents
      idx = 0
      while idx < preserves.size
        html = html.gsub("{__WP#{idx}}", preserves[idx])
        idx += 1
      end

      new_size = html.bytesize
      Rails.logger.info("[WhitespaceCompressor] Compressed body from #{orig_size} to #{new_size} bytes") if defined?(Rails) && Rails.logger

      # Update Content-Length header if present
      headers["Content-Length"] = new_size.to_s if headers["Content-Length"]

      [ status, headers, [ html ] ]
    else
      # Log skipping non-HTML response
      Rails.logger.info("[WhitespaceCompressor] Skipping non-HTML response") if defined?(Rails) && Rails.logger
      [ status, headers, body ]
    end
  end
end
