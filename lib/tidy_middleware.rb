require 'tidy'

class TidyMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)

    # Skip processing for JIT warmup requests
    return [status, headers, response] if env['HTTP_X_JIT_WARMUP'] == '1'

    # Only process text/html responses
    if headers['Content-Type']&.include?('text/html')
      # Collect the response body
      body = case response
             when String
               response
             when Array
               response.join
             when Enumerable
               response.inject(String.new) { |acc, part| acc << part }
             else
               # For other types, try to convert to string
               response.to_s
             end

      tidy = Tidy.new
      # Configure options for repair, minification, and XHTML output
      tidy.options.output_xhtml = true          # Output as XHTML
      tidy.options.doctype = 'strict'           # Use strict XHTML doctype (or 'html5' if preferred)
      tidy.options.clean = true                 # Enable cleanup/repair (e.g., fix legacy tags, structure)
      tidy.options.fix_bad_comments = true      # Repair invalid comments
      tidy.options.coerce_endtags = true        # Fix mismatched end tags
      tidy.options.drop_empty_elements = true   # Remove empty elements for minification
      tidy.options.drop_empty_paras = true      # Remove empty paragraphs
      tidy.options.hide_comments = true         # Remove comments
      tidy.options.indent = :no                 # No indentation
      tidy.options.wrap = 0                     # No line wrapping (infinite line length)
      tidy.options.vertical_space = :no         # No extra vertical spaces
      tidy.options.omit_optional_tags = true    # Omit optional tags (e.g., </p>, </li>)
      tidy.options.show_body_only = :yes        # Output body only (omit html/head if possible)
      tidy.options.quiet = true                 # Suppress non-error output
      tidy.options.show_warnings = false        # Suppress warnings for cleaner logs

      cleaned_body = tidy.clean(body)

      # Update response and headers
      headers['Content-Length'] = cleaned_body.length.to_s if headers['Content-Length']
      response = [cleaned_body]  # Wrap as array for Rack compatibility
    end

    [status, headers, response]
  end
end