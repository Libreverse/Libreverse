module ApplicationHelper
  require "base64"
  require "nokogiri"
  require "unicode"
  require "cgi"
  require 'uri'
  require 'digest/sha1' # Added for emoji_cache_key
  require 'erb' # Needed for url_encode

  # ===== Emoji Replacement Helper =====
  # Moved from EmojiReplacer middleware
  # Matches standard emojis, including sequences with ZWJ and skin tone modifiers
  EMOJI_REGEX = /(?:\p{Extended_Pictographic}(?:\p{Emoji_Modifier})?(?:\u{FE0F})?(?:\u{200D}\p{Extended_Pictographic}(?:\p{Emoji_Modifier})?(?:\u{FE0F})?)*)|[\u{1F1E6}-\u{1F1FF}]{2}/

  # Replaces emojis in a given text string with inline SVG <img> tags.
  # Uses caching to avoid redundant SVG processing.
  # Returns HTML-safe string.
  def render_emojis(text)
    return "".html_safe if text.blank? # Return empty safe string if input is blank

    # Detect if this looks like HTML content rather than plain text
    contains_html = text.include?('<') && text.include?('>')
    
    if contains_html
      # Use Nokogiri to parse HTML and only replace emojis in text nodes
      begin
        # Parse the HTML with Nokogiri
        doc = Nokogiri::HTML.fragment(text)
        
        # Process text nodes only
        doc.traverse do |node|
          # Only process text nodes (type 3)
          if node.text? && node.content.match?(EMOJI_REGEX)
            # Replace emojis in this text node
            replaced_content = node.content.gsub(EMOJI_REGEX) do |emoji|
              img_tag = Rails.cache.fetch(emoji_cache_key(emoji), expires_in: 12.hours) do
                build_emoji_img_tag(emoji)
              end
              # If img_tag is nil, fallback to original emoji
              img_tag || CGI.escapeHTML(emoji)
            end
            # Replace the node's content with the processed text
            node.content = replaced_content
          end
        end
        
        # Convert back to HTML string and mark as safe
        content = doc.to_html.html_safe
        # Ensure data URLs in img tags are properly encoded to prevent morph errors
        # Replace % with %25 in data URLs to avoid morphdom issues
        content.gsub!(/(<img[^>]*src=["']data:image\/svg\+xml;[^"']*["'][^>]*>)/) do |img_tag|
          img_tag.gsub(/%/, '%25')
        end
        return content
      rescue StandardError => e
        Rails.logger.error "EmojiHelper: Error processing HTML with Nokogiri: #{e.message}"
        # Fallback to normal processing if Nokogiri fails
      end
    end
    
    # Regular processing for plain text or fallback
    # Check if the text actually contains potential emojis before doing expensive gsub
    return text.html_safe unless text.match?(EMOJI_REGEX)

    processed_text = text.gsub(EMOJI_REGEX) do |emoji|
      img_tag = Rails.cache.fetch(emoji_cache_key(emoji), expires_in: 12.hours) do
        # Rails.logger.debug { "EmojiHelper: Cache miss for emoji '#{emoji}'. Building inline SVG." }
        build_emoji_img_tag(emoji)
      end

      # If img_tag is nil (e.g., SVG not found), fallback to original emoji
      img_tag || CGI.escapeHTML(emoji)
    end

    processed_text.html_safe
  rescue StandardError => e
    Rails.logger.error "EmojiHelper: Error rendering emojis: #{e.message}\nText: #{text[0..100]}"
    # Fallback safely in case of error
    CGI.escapeHTML(text || "").html_safe
  end

private

  # Generates a cache key for a given emoji.
  def emoji_cache_key(emoji)
    "emoji_helper/v13/#{Digest::SHA1.hexdigest(emoji)}" # Incremented version for encoding change
  end

  # Builds the inline SVG <img> tag for a given emoji using URL encoding.
  def build_emoji_img_tag(emoji)
    codepoints = emoji.codepoints.reject { |cp| cp == 0xFE0F }.map { |cp| cp.to_s(16) }.join("-")
    # Rails.logger.debug { "EmojiHelper: Emoji codepoints for '#{emoji}': #{codepoints}" }

    # Find the asset path using Vite manifest
    begin
      svg_path_from_vite = ViteRuby.instance.manifest.path_for("emoji/#{codepoints}.svg", { type: :image })
    rescue ViteRuby::MissingEntrypointError
      Rails.logger.warn "EmojiHelper: SVG manifest entry not found for emoji '#{emoji}' with codepoints '#{codepoints}'."
      return nil # Return nil if SVG is not in the manifest
    end

    return nil if svg_path_from_vite.blank?

    # Rails.logger.debug { "EmojiHelper: Resolved SVG path for emoji '#{emoji}': #{svg_path_from_vite}" }

    # Fetch the SVG content using the corrected Net::HTTP approach
    svg_content = read_vite_asset_content(svg_path_from_vite)

    # Build the <img> tag with inline Base64 SVG
    if svg_content
      # URL-encode the SVG content instead of Base64
      encoded_svg = ERB::Util.url_encode(svg_content)
      %(<img src="data:image/svg+xml,#{encoded_svg}" alt="#{CGI.escapeHTML(emoji)}" class="emoji" loading="eager" decoding="async" fetchpriority="low" draggable="false" tabindex="-1">)
    else
      nil # Return nil if content couldn't be loaded
    end
  rescue StandardError => e
    Rails.logger.error "EmojiHelper: Error building SVG tag for emoji '#{emoji}': #{e.message}"
    nil # Ensure fallback if any error occurs during build
  end

  # Helper to read asset content based on environment
  # Moved into private section of the helper module
  def read_vite_asset_content(path_from_manifest)
    return nil if path_from_manifest.blank?

    if Rails.env.development? || Rails.env.test?
      begin
        # Correctly construct the URI and fetch from Vite dev server
        vite_uri = URI.join(ViteRuby.instance.config.public_base_url, path_from_manifest)
        response_body = Net::HTTP.get(vite_uri)
        # Assuming success if we get a non-empty body, Net::HTTP.get raises errors on failure
        response_body.present? ? response_body : nil
      rescue StandardError => e
        Rails.logger.error "Error fetching asset from Vite dev server: #{e.message} for URI: #{vite_uri}"
        nil # Fallback
      end
    else
      # Read from public directory in production
      relative_path = path_from_manifest.sub(/^\/?#{ViteRuby.instance.config.public_output_dir}\//, '')
      public_path = Rails.root.join("public", ViteRuby.instance.config.public_output_dir, relative_path)
      File.exist?(public_path) ? File.read(public_path) : nil
    end
  rescue StandardError => e # Catch errors during path resolution/reading
    Rails.logger.error "Error reading Vite asset content for path '#{path_from_manifest}': #{e.message}"
    nil
  end

  # ===== End Emoji Replacement Helper =====

# Ensure subsequent original methods are public
public

  def auth_page?
    auth_paths = %w[/login /create-account /change-password /multi-phase-login]
    auth_paths.any? { |path| request.path.include?(path) }
  end

  def page_with_drawer?
    content_for?(:drawer)
  end

  def seo_config(key)
    SEO_CONFIG[key]
  end

  def sidebar_icon(path, additional_class = "")
    image_tag(path,
              class: "sidebar-icons #{additional_class}".strip,
              loading: "lazy",
              decoding: "async",
              fetchpriority: "low",
              draggable: "false",
              aria: { hidden: true },
              tabindex: "-1")
  end

  def svg_icon_data_url(icon_name)
    # Validate icon name to prevent path traversal
    unless icon_name.match?(/\A[a-zA-Z0-9_-]+\z/)
      Rails.logger.warn "Invalid SVG icon name requested: #{icon_name}"
      return ""
    end

    # Define potential directories and find the icon
    potential_dirs = [ Rails.root.join("app/icons"), Rails.root.join("app/images") ]
    icon_path = nil
    potential_dirs.each do |dir|
      path = dir.join("#{icon_name}.svg")
      if path.to_s.start_with?(dir.to_s) && File.exist?(path) && File.file?(path)
        icon_path = path
        break
      end
    end

    unless icon_path
      Rails.logger.warn "SVG icon not found in checked directories: #{icon_name}"
      return ""
    end

    # Read and validate SVG content
    svg_content = File.read(icon_path)

    # Basic SVG validation
    unless svg_content.include?("<svg") && svg_content.include?("</svg>")
      Rails.logger.warn "Invalid SVG content detected for icon: #{icon_name}"
      return ""
    end

    # Encode the SVG for a data URL using URL encoding instead of base64
    # Use ERB::Util.url_encode for proper SVG data URL encoding
    "data:image/svg+xml,#{ERB::Util.url_encode(svg_content)}"
  end

  # Generates a Base64-encoded data URI for a bitmap image.
  # Looks for the image in the source asset directories (e.g., app/images)
  # and automatically selects the most efficient format available (AVIF > WebP > PNG > JPG > GIF)
  # for the given base image path relative to the source root.
  #
  # @param source_relative_path [String] The path relative to the asset source root (e.g., "images/logo").
  # @return [String] The data URI string (e.g., "data:image/avif;base64,..."), or an empty string if no supported image is found.
  def bitmap_image_data_url(source_relative_path)
    # Basic validation for relative path
    unless source_relative_path.match?(%r{\A[a-zA-Z0-9_./-]+\z}) && !source_relative_path.include?("..")
      Rails.logger.warn "Invalid characters or path traversal attempt in source relative path: #{source_relative_path}"
      return ""
    end

    # Assuming 'app' is the primary source directory for assets like images
    # Adjust if your Vite setup uses a different root like 'app/frontend'
    source_root = Rails.root.join("app")

    # Define preferred formats in order of efficiency
    preferred_extensions = %w[.avif .webp .png .jpg .jpeg .gif]
    found_path = nil
    mime_type = nil

    # Find the first existing source file matching the preferred extensions
    preferred_extensions.each do |ext|
      potential_path = source_root.join("#{source_relative_path}#{ext}").cleanpath
      # Security check: Ensure the path is still within the intended source area
      next unless potential_path.to_s.start_with?(source_root.to_s) && File.exist?(potential_path) && File.file?(potential_path)

      found_path = potential_path
      mime_type = case ext
      when ".png" then "image/png"
      when ".jpg", ".jpeg" then "image/jpeg"
      when ".gif" then "image/gif"
      when ".webp" then "image/webp"
      when ".avif" then "image/avif"
      else "application/octet-stream"
      end
      break # Found the best available format
    end

    # If no suitable image was found
    unless found_path
      Rails.logger.warn "No suitable bitmap image found for source path: #{source_relative_path} within #{source_root}"
      return ""
    end

    # Read, encode, and return data URI for the found image
    begin
      image_data = File.binread(found_path)
      encoded_data = Base64.strict_encode64(image_data)
      "data:#{mime_type};base64,#{encoded_data}"
    rescue StandardError => e
      Rails.logger.error "Error reading or encoding bitmap image #{found_path}: #{e.message}"
      "" # Return empty string on error
    end
  end

  # --- User Preference Helpers ---

  # Gets a user preference value, returning a default if not set or user is nil.
  def get_user_preference(key, default_value = nil)
    # Uses the current_account helper defined in ApplicationController
    current_account ? UserPreference.get(current_account.id, key) || default_value : default_value
  end

  # Specifically checks if the sidebar is expanded.
  def sidebar_expanded?
    # Ensure the key matches what's used in SidebarReflex
    # UserPreference stores boolean true/false
    get_user_preference(:sidebar_expanded, false) == true
  end

  # Specifically checks if sidebar hover effect is enabled.
  def sidebar_hover_enabled?
    # Check for 't' as the value, consistent with other UserPreference values
    get_user_preference("sidebar_hover_enabled", 'f') == 't'
  end

  # Checks if a specific drawer is expanded.
  def drawer_expanded?(drawer_id = "main")
    # Construct the key matching the UserPreference ALLOWED_KEYS format
    key = "drawer_expanded_#{drawer_id}" # Keep as string
    # Retrieve the preference (stored as 't'/'f' or nil) and check if it's 't'
    get_user_preference(key, 'f') == 't' # Default to 'f' if not set
  end

  # Checks if a specific tutorial/item is dismissed.
  # Delegates to the existing helper in ApplicationController for consistency.
  # (Assumes tutorial_dismissed? helper is available via helper_method)
  # def item_dismissed?(key)
  #   tutorial_dismissed?(key)
  # end

  # --- End User Preference Helpers ---
end
