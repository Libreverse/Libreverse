module ApplicationHelper
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
    image_tag(vite_asset_path(path),
              class: "sidebar-icons #{additional_class}",
              loading: "eager",
              decoding: "async",
              fetchpriority: "high",
              data: { current_target: "image" },
              draggable: "false",
              aria: { hidden: true },
              tabindex: "-1")
  end

  def include_stylesheet(name)
    content_for :specific_stylesheets do
      vite_stylesheet_tag "~/stylesheets/#{name}.scss"
    end
  end

  def svg_icon_data_url(icon_name)
    # Validate icon name to prevent path traversal
    unless icon_name.match?(/\A[a-zA-Z0-9_-]+\z/)
      Rails.logger.warn "Invalid SVG icon name requested: #{icon_name}"
      return ""
    end

    icon_path = Rails.root.join("app", "icons", "#{icon_name}.svg")

    # Ensure the file exists and is within the icons directory
    unless File.exist?(icon_path) && File.file?(icon_path) &&
           icon_path.to_s.start_with?(Rails.root.join("app/icons").to_s)
      Rails.logger.warn "SVG icon not found or invalid path: #{icon_name}"
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
end
