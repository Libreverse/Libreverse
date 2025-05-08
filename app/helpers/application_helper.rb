# frozen_string_literal: true

module ApplicationHelper
  include EmojiHelper # Include the new helper
  require "base64"
  require "unicode"
  require "cgi"
  require "uri"

  # Ensure subsequent original methods are public

  def auth_page?
    auth_paths = %w[/login /create-account /change-password /multi-phase-login]
    auth_paths.any? { |path| request.path.include?(path) }
  end

  def page_with_drawer?
    content_for?(:drawer)
  end

  def seo_config(key)
    # Use the Rails config store instead of the old constant
    Rails.application.config.x.seo_config[key.to_s]
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

      # Resolve any symlinks before continuing. This prevents a malicious symlink
      # inside the app directory from escaping to an arbitrary location on disk.
      begin
        resolved_path = Pathname.new(File.realpath(potential_path))
      rescue Errno::ENOENT, Errno::EINVAL
        # The file doesn't exist or couldn't be resolved – skip this extension.
        next
      end

      # Security check: Ensure the *resolved* path is within the intended source area
      next unless resolved_path.to_s.start_with?(source_root.to_s) && resolved_path.file?

      found_path = resolved_path
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

  # Get expanded state of sidebar from user preferences
  def sidebar_expanded?
    return "f" unless current_account

    UserPreference.get(current_account.id, :sidebar_expanded) == "t"
  end

  # Check if the sidebar hover feature is enabled for the current user
  def sidebar_hover_enabled?
    return "f" unless current_account

    # Ensure we check for 't' to match the stored pattern
    UserPreference.get(current_account.id, "sidebar_hover_enabled") == "t"
  end

  # Checks if a specific drawer is expanded.
  def drawer_expanded?(drawer_id = "main")
    # Construct the key matching the UserPreference ALLOWED_KEYS format
    key = "drawer_expanded_#{drawer_id}" # Keep as string
    # Retrieve the preference (stored as 't'/'f' or nil) and check if it's 't'
    get_user_preference(key, "f") == "t" # Default to 'f' if not set
  end

  # Checks if a specific tutorial/item is dismissed.
  # Delegates to the existing helper in ApplicationController for consistency.
  # (Assumes tutorial_dismissed? helper is available via helper_method)
  # def item_dismissed?(key)
  #   tutorial_dismissed?(key)
  # end

  # --- End User Preference Helpers ---

  # --- SEO Asset Path Helpers (Moved from initializer) ---

  # Resolves SEO-specific asset paths (e.g., with @ or ~/ prefixes)
  # Note: Assumes vite_asset_path is available in this helper context.
  def seo_asset_path(path)
    if path.is_a?(String)
      if path.start_with?("@")
        # For @ prefixed assets (e.g., @libreverse-logo.svg), look in images directory
        vite_asset_path("images/#{path.sub('@', '')}")
      elsif path.start_with?("~/")
        # For ~/ prefixed assets, use as-is with vite_asset_path
        vite_asset_path(path)
      else
        # Return unchanged for other paths
        path
      end
    else
      # Return unchanged for non-string values
      path
    end
  end

  # Convenience method to get SEO config value, resolving asset paths where needed.
  # Accesses the configuration stored in Rails.application.config.x.seo_config
  def seo_config_with_assets(key)
    value = Rails.application.config.x.seo_config[key.to_s]

    # Special handling for asset keys that need path resolution
    if %w[preview_image shortcut_icon apple_touch_icon mask_icon].include?(key.to_s)
      seo_asset_path(value)
    else
      value
    end
  end

  # --- End SEO Asset Path Helpers ---

  # --- Vite Asset Inlining Helpers ---
  def inline_vite_stylesheet(name_with_prefix, **options)
    if Rails.env.development? || Rails.env.test?
      # In development, Vite serves CSS as JS to enable HMR. We therefore load it
      # with a <script type="module"> tag so the dev-server can handle updates.
      tag.script(nil, type: "module", src: vite_asset_path(name_with_prefix))
    else
      # In production, inline the compiled CSS to avoid an extra request.
      manifest_key = name_with_prefix.sub(%r{^~/}, "")
      content = get_vite_asset_content(manifest_key, type: :stylesheet)
      # `content` is compiler-generated CSS, safe to insert verbatim.
      # Attach the current request's CSP nonce so that inline styles are allowed
      nonce_opt = { nonce: content_security_policy_nonce }
      merged_opts = options.merge(nonce_opt) { |_k, old, new| old || new }
      # rubocop:disable Rails/OutputSafety
      tag.style(content.html_safe, **merged_opts) if content
      # rubocop:enable Rails/OutputSafety
    end
  end

  def inline_vite_javascript(name_with_prefix, **options)
    if Rails.env.development? || Rails.env.test?
      # In development and test, keep the standard Vite tag so the dev server
      # (and HMR) handles JavaScript resources.
      vite_javascript_tag(name_with_prefix, **options)
    else
      # In production, inline the content directly
      manifest_key = name_with_prefix.sub(%r{^~/}, "")
      content = get_vite_asset_content(manifest_key, type: :javascript)
      if content
        # JS is generated by Vite; mark as safe for direct embedding.
        # Attach the current request's CSP nonce so that inline scripts are allowed
        nonce_opt = { nonce: content_security_policy_nonce }
        merged_opts = { type: "module" }.merge(options).merge(nonce_opt) { |_k, old, new| old || new }
        # rubocop:disable Rails/OutputSafety
        tag.script(content.html_safe, **merged_opts)
        # rubocop:enable Rails/OutputSafety
      end
    end
  end

  def inline_vite_legacy_javascript(name_with_prefix, **options)
    if Rails.env.development? || Rails.env.test?
      # In development, use standard vite tags
      vite_legacy_javascript_tag(name_with_prefix)
    else
      # In production, inline the content directly
      manifest_key = name_with_prefix.sub(%r{^~/}, "")
      legacy_manifest_key = "#{File.basename(manifest_key, '.*')}-legacy#{File.extname(manifest_key)}"
      content = get_vite_asset_content(manifest_key, type: :javascript, legacy_lookup: true)
      content ||= get_vite_asset_content(legacy_manifest_key, type: :javascript)

      if content
        options_without_type = options.dup
        options_without_type.delete(:type) # Ensure no type="module"
        # Attach the current request's CSP nonce so that inline scripts are allowed
        nonce_opt = { nonce: content_security_policy_nonce }
        merged_opts = options_without_type.merge(nonce_opt) { |_k, old, new| old || new }
        # rubocop:disable Rails/OutputSafety
        tag.script(content.html_safe, **merged_opts)
        # rubocop:enable Rails/OutputSafety
      end
    end
  end

  # Inline font helper: Generates a style tag with an embedded @font-face rule.
  # Example usage: inline_vite_font('~/fonts/myfont.woff2', font_family: 'MyFont')
  def inline_vite_font(font_path, **options)
    manifest_key = font_path.sub(%r{^~/}, "")
    content = get_vite_asset_content(manifest_key, type: :font)
    return if content.blank?

    ext = File.extname(manifest_key).downcase
    mime = case ext
    when ".woff2" then "font/woff2"
    when ".woff" then "font/woff"
    when ".ttf"   then "font/ttf"
    when ".otf"   then "font/otf"
    else "application/octet-stream"
    end

    base64_content = Base64.strict_encode64(content)
    data_uri = "data:#{mime};base64,#{base64_content}"

    font_family = options.delete(:font_family) || File.basename(manifest_key, ext)
    css = <<~CSS
      @font-face {
        font-family: '#{font_family}';
        src: url(\"#{data_uri}\") format(\"#{ext.delete('.')}\");
        font-weight: normal;
        font-style: normal;
      }
    CSS

    nonce_opt = Rails.env.production? ? { nonce: content_security_policy_nonce } : {}
    # rubocop:disable Rails/OutputSafety
    tag.style(css.html_safe, **nonce_opt.merge(options))
    # rubocop:enable Rails/OutputSafety
  end

  private

  # Renamed from inline_vite_asset_content to get_vite_asset_content for clarity
  # Now accepts manifest_key directly.
  def get_vite_asset_content(manifest_key, type:, legacy_lookup: false)
    # The `legacy_lookup` is a hint. The actual mechanism in vite_rails/vite_ruby for path_for might vary.
    # It might be an option to path_for, or it might require a different manifest key.
    if legacy_lookup
      # Try with a potential legacy: true option if path_for supports it (speculative)
      # Or this logic could be expanded if ViteRuby.instance.manifest has a dedicated legacy method.
      begin
        manifest_path = ViteRuby.instance.manifest.path_for(manifest_key, type: type, legacy: true)
      rescue ArgumentError
        # if legacy: true is not a valid option for path_for
        manifest_path = ViteRuby.instance.manifest.path_for(manifest_key, type: type)
      end
    else
      manifest_path = ViteRuby.instance.manifest.path_for(manifest_key, type: type)
    end

    return unless manifest_path

    return nil unless Rails.env.production?

      # We no longer inline assets in non-production environments, so bail early.

      # Production
      # In production, manifest_path includes the hash, e.g., 'application-buildhash.css'
      # It's relative to public/<public_output_dir>
      # ViteRuby.instance.config.public_output_dir is typically 'vite' or 'vite-production'
      base_dir = Rails.root.join("public", ViteRuby.instance.config.public_output_dir)
      # Ensure manifest_path is treated as relative to base_dir if it accidentally includes public_output_dir again
      relative_manifest_path = manifest_path.sub(%r{^/?#{Regexp.escape(ViteRuby.instance.config.public_output_dir)}/}, "")
      file_path = base_dir.join(relative_manifest_path)

      if File.exist?(file_path)
        File.read(file_path)
      else
        Rails.logger.error "[ViteInline] Asset not found at #{file_path} (derived from manifest key: #{manifest_key}, manifest path: #{manifest_path})"
        nil
      end
  rescue StandardError => e
    Rails.logger.error "[ViteInline] Error in get_vite_asset_content for manifest key '#{manifest_key}': #{e.class} - #{e.message}\n#{e.backtrace.take(5).join("\n")}"
    nil
  end
  # --- End Vite Asset Inlining Helpers ---
end
