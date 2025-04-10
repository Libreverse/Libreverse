module ApplicationHelper
  require 'base64'
  require 'nokogiri'

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
    unless icon_name.match?(%r{\A[a-zA-Z0-9_-]+\z})
      Rails.logger.warn "Invalid SVG icon name requested: #{icon_name}"
      return ""
    end

    # Define potential directories and find the icon
    potential_dirs = [Rails.root.join("app", "icons"), Rails.root.join("app", "images")]
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
      if potential_path.to_s.start_with?(source_root.to_s) && File.exist?(potential_path) && File.file?(potential_path)
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
end
