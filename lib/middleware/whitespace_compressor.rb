# frozen_string_literal: true

require "re2"

class WhitespaceCompressor
  def initialize(app)
    @app = app
    # Compile RE2 patterns once during initialization
    @preserve_pattern = %r{(<textarea>[\s\S]*?</textarea>|<pre>[\s\S]*?</pre>|<script>[\s\S]*?</script>|<iframe>[\s\S]*?</iframe>)}
    @pattern_comments = RE2::Regexp.new('<!--[\s\S]*?-->', log_errors: false)
    @pattern_between_tags = RE2::Regexp.new('>\s+<', log_errors: false)
    @pattern_spaces = RE2::Regexp.new('\s{2,}', log_errors: false)
    @pattern_attr_eq = RE2::Regexp.new('(<[^>]*?)\s*=\s*([^>]*>)', log_errors: false)
    @pattern_attr_sp = RE2::Regexp.new('(<[^>]*?)\s{2,}([^>]*>)', log_errors: false)
  end

  def call(env)
    status, headers, body = @app.call(env)
    return [ status, headers, body ] unless headers["Content-Type"]&.include?("text/html")

    # Step 1: Assemble HTML efficiently
    chunks = []
    body.each { |chunk| chunks << chunk.encode("UTF-8", invalid: :replace, undef: :replace) }
    html = chunks.join

    # Step 2: Split into preserve and non-preserve parts
    parts = html.split(@preserve_pattern, -1)

    # Step 3: Process only non-preserve parts
    i = 0
    len = parts.length
    while i < len
      unless i.odd?
        part = parts[i]
        part = RE2.GlobalReplace(part, @pattern_comments, "")
        part = RE2.GlobalReplace(part, @pattern_between_tags, "><")
        part = RE2.GlobalReplace(part, @pattern_spaces, " ")
        part = RE2.GlobalReplace(part, @pattern_attr_eq, '\1=\2')
        part = RE2.GlobalReplace(part, @pattern_attr_sp, '\1 \2')
        parts[i] = part
      end
      i += 1
    end

    # Step 4: Reassemble HTML
    html = parts.join

    # Step 5: Update headers and return response
    headers["Content-Length"] = html.bytesize.to_s
    headers["Content-Encoding"] = "UTF-8"
    [ status, headers, [ html ] ]
  end
end
