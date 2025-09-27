# Service to fetch CSS from Vite dev server during development
# Handles both direct CSS files and CSS extracted from JavaScript modules
class ViteCssFetcher
  class << self
    # Fetch CSS content from Vite dev server
    # @param css_entry [String] The CSS file path (e.g., "emails.scss")
    # @return [String] The CSS content or empty string if failed
    def fetch_css(css_entry)
      css_path = normalize_css_path(css_entry)
      vite_url = build_vite_url(css_path)

      Rails.logger.debug "[ViteCssFetcher] Fetching CSS from: #{vite_url}"

      response = HTTParty.get(vite_url)

      if response.code == 200
        extract_css_from_response(response.body)
      else
        Rails.logger.warn "[ViteCssFetcher] Failed to fetch CSS: HTTP #{response.code}"
        ""
      end
    rescue StandardError => e
      Rails.logger.warn "[ViteCssFetcher] Error fetching CSS: #{e.message}"
      ""
    end

    private

    # Normalize CSS path for Vite dev server
    def normalize_css_path(css_entry)
      # Convert ~/stylesheets/emails.scss to stylesheets/emails.scss
      css_entry.sub(%r{^~/}, "")
    end

    # Build the full Vite dev server URL
    def build_vite_url(css_path)
      vite_host = begin
                    ViteRuby.config.host
      rescue StandardError
                    "localhost"
      end
      vite_port = begin
                    ViteRuby.config.port
      rescue StandardError
                    5173
      end

      # Use the vite-dev prefix for development server
      "http://#{vite_host}:#{vite_port}/vite-dev/#{css_path}"
    end

    # Extract CSS from response body
    # Handles both direct CSS responses and Vite HMR JavaScript containing CSS
    def extract_css_from_response(response_body)
      # Check for Vite HMR JavaScript first (takes precedence)
      return extract_css_from_vite_hmr(response_body) if vite_hmr_response?(response_body)

      # If response looks like pure CSS
      return response_body if css_response?(response_body)

      # If response is other JavaScript, try generic extraction
      return extract_css_from_javascript(response_body) if javascript_response?(response_body)

      # If we can't determine the type, return as-is
      response_body
    end

    # Check if response is Vite HMR JavaScript
    def vite_hmr_response?(content)
      content.include?("__vite__css") ||
        content.include?("createHotContext") ||
        content.include?("updateStyle") ||
        content.include?("@vite/client")
    end

    # Extract CSS from Vite HMR JavaScript wrapper
    def extract_css_from_vite_hmr(js_content)
      Rails.logger.debug "[ViteCssFetcher] Extracting CSS from Vite HMR JavaScript"

      # Look for the __vite__css variable assignment
      css_match = js_content.match(/const __vite__css = "([^"]*)"/)
      if css_match
        css_content = css_match[1]
        # Unescape JavaScript string escaping
        css_content = css_content.gsub('\\"', '"')
                                 .gsub("\\'", "'")
                                 .gsub('\\n', "\n")
                                 .gsub('\\r', "\r")
                                 .gsub('\\t', "\t")
                                 .gsub("\\\\", "\\")

        Rails.logger.debug "[ViteCssFetcher] Extracted CSS: #{css_content.length} characters"
        return css_content
      end

      # Fallback: look for other CSS injection patterns in Vite
      vite_css_patterns = [
        /updateStyle\((?>[^,]+),\s*"(?>[^"]+)"/,
        /\.textContent\s*=\s*"(?>[^"]+)"/,
        /innerHTML\s*=\s*"(?>[^"]+)"/
      ]

      vite_css_patterns.each do |pattern|
        match = js_content.match(pattern)
        next unless match

        css_content = match[1]
        # Unescape and return
        return css_content.gsub('\\"', '"').gsub('\\n', "\n")
      end

      Rails.logger.warn "[ViteCssFetcher] Could not extract CSS from Vite HMR response"
      ""
    end

    # Check if response looks like CSS
    def css_response?(content)
      css_patterns = [
        /^\s*@import/,
        %r{^\s*/\*.*\*/},
        /^\s*[.#]?[\w-]+\s*\{/,
        /^\s*body\s*\{/,
        /^\s*html\s*\{/
      ]

      css_patterns.any? { |pattern| content.match?(pattern) }
    end

    # Check if response looks like JavaScript
    def javascript_response?(content)
      js_patterns = [
        /^import\s+/,
        /^export\s+/,
        /^const\s+/,
        /^let\s+/,
        /^var\s+/,
        /^function\s+/,
        %r{^//\s+}
      ]

      js_patterns.any? { |pattern| content.match?(pattern) }
    end

    # Extract CSS from JavaScript response
    # This handles cases where Vite serves CSS as part of JavaScript modules
    def extract_css_from_javascript(js_content)
      # Look for CSS string literals in the JavaScript
      css_patterns = [
        /"(?>[^"]*(?:color|background|font|margin|padding|border)[^"]*)"/,
        /'(?>[^']*(?:color|background|font|margin|padding|border)[^']*)'/,
        /`(?>[^`]*(?:color|background|font|margin|padding|border)[^`]*)`/
      ]

      css_content = ""

      css_patterns.each do |pattern|
        matches = js_content.scan(pattern)
        matches.each do |match|
          potential_css = match.first
          css_content += "#{potential_css}\n" if valid_css?(potential_css)
        end
      end

      # If no CSS found in JS, try to extract from style injection code
      css_content = extract_from_style_injection(js_content) if css_content.empty?

      css_content.strip
    end

    # Check if extracted string looks like valid CSS
    def valid_css?(content)
      return false if content.length < 10

      # Look for CSS-like patterns
      css_indicators = [
        /[{;}]/, # CSS delimiters
        /:\s*[^;]+;/,              # Property: value; patterns
        /@\w+/,                    # At-rules like @media, @import
        /\.\w+\s*\{/,              # Class selectors
        /#\w+\s*\{/                # ID selectors
      ]

      css_indicators.any? { |pattern| content.match?(pattern) }
    end

    # Extract CSS from Vite's style injection code
    def extract_from_style_injection(js_content)
      # Look for common Vite style injection patterns
      injection_patterns = [
        /updateStyle\s*\(\s*["'`]([^"'`]+)["'`]/,
        /insertRule\s*\(\s*["'`]([^"'`]+)["'`]/,
        /cssText\s*=\s*["'`]([^"'`]+)["'`]/,
        /innerHTML\s*\(\s*["'`]([^"'`]+)["'`]/
      ]

      css_content = ""

      injection_patterns.each do |pattern|
        matches = js_content.scan(pattern)
        matches.each do |match|
          potential_css = match.first
          css_content += "#{potential_css}\n" if valid_css?(potential_css)
        end
      end

      css_content
    end
  end
end
