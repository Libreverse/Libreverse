# Frontend Configuration
# This file contains all frontend-related configurations including:
# - CableReady
# - Emoji Replacement
# - StimulusReflex

# ===== CableReady Configuration =====
CableReady.configure do |config|
  # Enable/disable exiting / warning when the sanity checks fail options:
  # `:exit` or `:warn` or `:ignore`
  #
  config.on_failed_sanity_checks = :exit

  # Enable/disable assets compilation
  # `true` or `false`
  #
  # config.precompile_assets = true

  # Define your own custom operations
  # https://cableready.stimulusreflex.com/customization#custom-operations
  #
  # config.add_operation_name :jazz_hands

  # Change the default Active Job queue used for broadcast_later and broadcast_later_to
  #
  # config.broadcast_job_queue = :default

  # Specify a default debounce time for CableReady::Updatable callbacks
  # Doing so is a best practice to avoid heavy ActionCable traffic
  config.updatable_debounce_time = 0.1.seconds
end

# ===== Emoji Replacement =====
class EmojiReplacer
    require "unicode"
    require "nokogiri"

    EMOJI_REGEX = /(?:\p{Extended_Pictographic}(?:\uFE0F)?(?:\u200D\p{Extended_Pictographic}(?:\uFE0F)?)*)|[\u{1F1E6}-\u{1F1FF}]{2}/

    # Default selectors to exclude from emoji replacement
    DEFAULT_EXCLUDE_SELECTORS = %w[script style pre code textarea svg noscript].freeze

    def initialize(app, options = {})
      @app = app
      @exclude_selectors = options[:exclude_selectors] || DEFAULT_EXCLUDE_SELECTORS
      Rails.logger.debug { "EmojiReplacer: Initialized with exclude selectors: #{@exclude_selectors.inspect}" }
    end

    def call(env)
      Rails.logger.debug { "EmojiReplacer: Processing request for #{env['PATH_INFO']}" }

      status, headers, body = @app.call(env)

      if headers["Content-Type"]&.include?("text/html")
        Rails.logger.debug "EmojiReplacer: Detected text/html content type"

        new_body = ""
        body.each do |part|
          # Process HTML with Nokogiri to exclude certain elements
          new_part = if @exclude_selectors.any? && part.include?("<html")
            process_with_nokogiri(part)
          else
            replace_emojis(part)
          end

          new_body << new_part
        end

        # Update the body and Content-Length
        body = [ new_body ]
        headers["Content-Length"] = new_body.bytesize.to_s

        Rails.logger.debug do
          "EmojiReplacer: Completed emoji replacement. Updated Content-Length to #{new_body.bytesize}."
        end
      else
        Rails.logger.debug "EmojiReplacer: Skipping emoji replacement. Content-Type is not text/html."
      end

      # Return the modified response
      [ status, headers, body ]
    rescue StandardError => e
      Rails.logger.error "EmojiReplacer: Error processing request: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      [ 500, { "Content-Type" => "text/plain" }, [ "Internal Server Error" ] ]
    end

  private

    def process_with_nokogiri(html)
        # Prevent processing of obviously invalid HTML
        if html.blank? || html.bytesize > 5.megabytes
          Rails.logger.warn "EmojiReplacer: Skipping processing of invalid HTML"
          return html
        end

        # Enforce processing timeout to prevent DoS
        Timeout.timeout(1.0) do
          doc = Nokogiri::HTML4.parse(html)

          # Create a set of nodes to exclude
          exclude_nodes = Set.new
          @exclude_selectors.each do |selector|
            doc.css(selector).each do |node|
              exclude_nodes.add(node)
            end
          end

          # Process text nodes that are not within excluded elements
          doc.traverse do |node|
            next unless node.text? && !within_excluded_node?(node, exclude_nodes)

            # Replace emojis with HTML nodes instead of text
            replaced_content = replace_emojis_with_nodes(node.content, doc)

            # Only replace if we actually found and replaced an emoji
            if replaced_content != node.content
              # Create a fragment for the replaced content
              fragment = Nokogiri::HTML4.fragment(replaced_content)
              # Replace the original node with the fragment
              node.replace(fragment)
            end
          end

          doc.to_html
        end
    rescue Timeout::Error
      Rails.logger.error "EmojiReplacer: Processing timeout"
      html
    rescue Nokogiri::XML::SyntaxError => e
      Rails.logger.error "EmojiReplacer: HTML parsing error: #{e.message}"
      html
    rescue StandardError => e
      Rails.logger.error "EmojiReplacer: Processing error: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      html
    end

    def replace_emojis_with_nodes(text, _doc)
      return text unless text.match?(EMOJI_REGEX)

      text.gsub(EMOJI_REGEX) do |emoji|
        match_data = Regexp.last_match
        context = extract_context(text, match_data.begin(0), match_data.end(0))
        Rails.logger.debug { "EmojiReplacer: Detected emoji '#{emoji}' around: '#{context}'" }

        # Use caching
        img_tag = Rails.cache.fetch(cache_key(emoji), expires_in: 12.hours) do
          Rails.logger.debug { "EmojiReplacer: Cache miss for emoji '#{emoji}'. Building inline SVG." }
          build_inline_svg(emoji)
        end

        if img_tag
          Rails.logger.debug { "EmojiReplacer: Replacing emoji '#{emoji}' with img tag." }
          img_tag
        else
          Rails.logger.warn "EmojiReplacer: Failed to build img tag for emoji '#{emoji}'. Using original emoji."
          emoji
        end
      end
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

    def replace_emojis(text)
      text.gsub(EMOJI_REGEX) do |emoji|
        match_data = Regexp.last_match
        context = extract_context(text, match_data.begin(0), match_data.end(0))
        Rails.logger.debug { "EmojiReplacer: Detected emoji '#{emoji}' around: '#{context}'" }

        # Use caching
        img_tag = Rails.cache.fetch(cache_key(emoji), expires_in: 12.hours) do
          Rails.logger.debug { "EmojiReplacer: Cache miss for emoji '#{emoji}'. Building inline SVG." }
          build_inline_svg(emoji)
        end

        if img_tag
          Rails.logger.debug { "EmojiReplacer: Replacing emoji '#{emoji}' with img tag." }
          img_tag
        else
          Rails.logger.warn "EmojiReplacer: Failed to build img tag for emoji '#{emoji}'. Using original emoji."
          emoji
        end
      end
    end

    def cache_key(emoji)
      "emoji_replacer/v10/#{emoji}"
    end

    def build_inline_svg(emoji)
      codepoints = emoji.codepoints.reject { |cp| cp == 0xFE0F }.map { |cp| cp.to_s(16) }.join("-")
      Rails.logger.debug { "EmojiReplacer: Emoji codepoints for '#{emoji}': #{codepoints}" }

      # Get the path to the SVG file
      svg_path_from_vite = ViteRuby.instance.manifest.path_for("emoji/#{codepoints}.svg")
      Rails.logger.debug { "EmojiReplacer: Resolved SVG path for emoji '#{emoji}': #{svg_path_from_vite}" }

      if svg_path_from_vite.blank?
        Rails.logger.warn "EmojiReplacer: SVG path not found for emoji '#{emoji}' with codepoints '#{codepoints}'."
        return CGI.escapeHTML(emoji)
      end

      # Determine the actual file path in the file system
      if Rails.env.development? || Rails.env.test?
        # In development, the files are served from app/emoji
        svg_file_path = Rails.root.join("app", "emoji", "#{codepoints}.svg")
      else
        # In production, the files are precompiled and served from public/vite-production
        # We need to strip the URL path and get the actual file path
        relative_path = svg_path_from_vite.sub(%r{^/[^/]+/}, "")
        svg_file_path = Rails.root.join("public", relative_path)
      end

      Rails.logger.debug { "EmojiReplacer: SVG file path: #{svg_file_path}" }

      if File.exist?(svg_file_path)
        svg_content = File.read(svg_file_path)

        # Create a data URL from the SVG content using URL encoding instead of base64
        # Use ERB::Util.url_encode for proper SVG data URL encoding
        data_url = "data:image/svg+xml,#{ERB::Util.url_encode(svg_content)}"

        # Create an img tag with the data URL using the original emoji as alt text
        img_tag = %(<img src="#{data_url}" alt="#{emoji}" class="emoji" loading="eager" decoding="async" fetchpriority="low" draggable="false" tabindex="-1">)

        Rails.logger.debug { "EmojiReplacer: Built img tag with data URL for emoji '#{emoji}'" }
        img_tag
      else
        Rails.logger.warn "EmojiReplacer: SVG file not found at '#{svg_file_path}' for emoji '#{emoji}'."
        CGI.escapeHTML(emoji)
      end
    rescue StandardError => e
      Rails.logger.error "EmojiReplacer: Failed to build inline SVG for emoji '#{emoji}': #{e.message}"
      CGI.escapeHTML(emoji)
    end

    def extract_context(text, match_start, match_end, window = 10)
      start_index = [ match_start - window, 0 ].max
      end_index = [ match_end + window, text.length ].min
      text[start_index...end_index]
    end
end

# ===== StimulusReflex Configuration =====

StimulusReflex.configure do |config|
  # Enable/disable exiting / warning when the sanity checks fail:
  # `:exit` or `:warn` or `:ignore`
  #
  config.on_failed_sanity_checks = :exit

  # Enable/disable exiting / warning when there is no default URLs specified in environment config
  # `:warn` or `:ignore`
  #
  # config.on_missing_default_urls = :warn

  # Enable/disable assets compilation
  # `true` or `false`
  #
  # config.precompile_assets = true

  # Override the CableReady operation used for morphing and replacing content
  #
  # config.morph_operation = :morph
  # config.replace_operation = :inner_html

  # Override the parent class that the StimulusReflex ActionCable channel inherits from
  #
  # config.parent_channel = "ApplicationCable::Channel"

  # Override the logger that the StimulusReflex uses; default is Rails' logger
  # eg. Logger.new(RAILS_ROOT + "/log/reflex.log")
  #
  # config.logger = Rails.logger

  # Customize server-side Reflex logging format, with optional colorization:
  # Available tokens: session_id, session_id_full, reflex_info, operation, id, id_full, mode, selector, operation_counter, connection_id, connection_id_full, timestamp
  # Available colors: red, green, yellow, blue, magenta, cyan, white
  # You can also use attributes from your ActionCable Connection's identifiers that resolve to valid ActiveRecord models
  # eg. if your connection is `identified_by :current_user` and your User model has an email attribute, you can access r.email (it will display `-` if the user isn't logged in)
  # Learn more at: https://docs.stimulusreflex.com/appendices/troubleshooting#stimulusreflex-logging
  #
  # config.logging = proc { "[#{session_id}] #{operation_counter.magenta} #{reflex_info.green} -> #{selector.cyan} via #{mode} Morph (#{operation.yellow})" }

  # Optimized for speed, StimulusReflex doesn't enable Rack middleware by default.
  # If you are using Page Morphs and your app uses Rack middleware to rewrite part of the request path, you must enable those middleware modules in StimulusReflex.
  #
  # Learn more about registering Rack middleware in Rails here: https://guides.rubyonrails.org/rails_on_rack.html#configuring-middleware-stack
end
