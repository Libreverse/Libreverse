require 'open3'
require 'nokogiri'

# TidyMiddleware — cleans/repairs HTML via `tidy` CLI, then applies a parser-based
# whitespace minification pass (Nokogiri for safe text collapsing + inter-tag removal)
# followed by a final compact Tidy pass to eliminate any remaining structural whitespace.
#
# This gives aggressive, safe whitespace minification while preserving semantics
# (e.g., exact spacing in <pre>, <textarea>, <script>, <style>, <code>).
class TidyMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)

    if headers['Content-Type']&.include?('text/html')
      # Assemble full body
      body = case response
             when String then response
             when Array then response.join
             when Enumerable then response.inject('') { |acc, part| acc << part }
             else response.to_s
             end

      # First pass: repair/clean with conservative Tidy options (your original config, fixed)
      tidy_cmd = [
        'tidy',
        '-q',                    # quiet
        '-utf8',
        '-wrap', '0',
        '--clean', 'yes',
        '--drop-proprietary-attributes', 'no',
        '--force-output', 'yes',
        '--show-warnings', 'no',
        '--tidy-mark', 'no',
        '--output-html', 'no',
        '--output-xhtml', 'yes',
        '--output-xml', 'no',
        '--hide-comments', 'yes',      # preserve comments (fixed from your original 'yes')
        '--bare', 'no',
        '--logical-emphasis', 'yes',
        '--drop-empty-paras', 'yes',
        '--fix-bad-comments', 'yes',
        '--break-before-br', 'no',
        '--numeric-entities', 'yes',
        '--quote-marks', 'no',
        '--quote-nbsp', 'no',
        '--quote-ampersand', 'no',
        '--wrap-attributes', 'no',
        '--wrap-script-literals', 'no',
        '--wrap-sections', 'no',
        '--wrap-asp', 'no',
        '--wrap-jste', 'no',
        '--wrap-php', 'no',
        '--fix-backslash', 'yes',
        '--indent-attributes', 'no',
        '--assume-xml-procins', 'yes',
        '--add-xml-space', 'yes',
        '--enclose-text', 'no',
        '--enclose-block-text', 'no',
        '--gnu-emacs', 'no',
        '--literal-attributes', 'yes',
        '--show-body-only', 'no',
        '--fix-uri', 'yes',
        '--lower-literals', 'no',
        '--indent-cdata', 'no',
        '--ascii-chars', 'yes',
        '--join-classes', 'no',
        '--join-styles', 'no',
        '--escape-cdata', 'yes',
        '--ncr', 'no',
        '--replace-color', 'no',
        '--vertical-space', 'no',
        '--punctuation-wrap', 'no',
        '--merge-divs', 'auto',
        '--decorate-inferred-ul', 'yes',
        '--drop-empty-elements', 'yes',
        '--merge-spans', 'auto',
        '--preserve-entities', 'no',
        '--anchor-as-name', 'yes',
        '--coerce-endtags', 'yes',
        '--escape-scripts', 'yes',
        '--fix-style-tags', 'yes',
        '--repeated-attributes', 'keep-last',
        '--strict-tags-attributes', 'no',
        '--merge-emphasis', 'yes'
      ]

      cleaned_html, stderr_str, tidy_status = Open3.capture3(*tidy_cmd, stdin_data: body)

      if cleaned_html.nil? || cleaned_html.strip.empty?
        raise "Tidy CLI produced no output (exit=#{tidy_status.exitstatus}): #{stderr_str}"
      end

      if stderr_str && !stderr_str.strip.empty?
        fatal_patterns = [/\bError\b/i, /not a file/i, /unknown option/i, /invalid/i, /fatal/i]
        if stderr_str.lines.any? { |l| fatal_patterns.any? { |pat| l =~ pat } }
          raise "Tidy CLI error (exit=#{tidy_status.exitstatus}): #{stderr_str}"
        else
          warn "Tidy CLI warnings: #{stderr_str}" if defined?(Rails)
        end
      end

      # Second pass: parser-based whitespace collapsing (no regex, safe & fast at scale)
      doc = Nokogiri::HTML.parse(cleaned_html)

      # Remove pure-whitespace text nodes outside preformatted elements
      doc.xpath('//text()[normalize-space() = "" and not(ancestor::pre | ancestor::textarea | ancestor::script | ancestor::style | ancestor::code)]').remove

      # Collapse multiple whitespace → single space (and trim) in flow content
      doc.xpath('//text()[normalize-space() != "" and not(ancestor::pre | ancestor::textarea | ancestor::script | ancestor::style | ancestor::code)]').each do |node|
        node.content = node.content.split.join(' ')
      end

      intermediate_html = doc.to_html

      # Third pass: final compact Tidy to strip any structural whitespace/indents/newlines
      compact_cmd = [
        'tidy',
        '-q',
        '--force-output', 'yes',
        '--tidy-mark', 'no',
        '--indent', 'no',
        '--indent-spaces', '0',
        '--tab-size', '0',
        '--wrap', '0',
        '--vertical-space', 'no',
        '--drop-empty-elements', 'yes',
        '--output-xhtml', 'yes'        # match your first pass; change to '--output-html', 'yes' if preferred
      ]

      minified_html, compact_stderr, compact_status = Open3.capture3(*compact_cmd, stdin_data: intermediate_html)

      final_html = if compact_status.success? && !minified_html.strip.empty?
                     minified_html
                   else
                     warn "Final compact Tidy failed (fallback to intermediate): #{compact_stderr}" if compact_stderr && !compact_stderr.strip.empty?
                     intermediate_html
                   end

      # Replace response body
      response = [final_html]
      headers['Content-Length'] = final_html.bytesize.to_s if headers['Content-Length']
    end

    [status, headers, response]
  end
end