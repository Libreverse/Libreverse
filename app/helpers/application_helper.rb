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
    icon_path = Rails.root.join("app", "icons", "#{icon_name}.svg")
    return "" unless File.exist?(icon_path)

    svg_content = File.read(icon_path)
    # Encode the SVG for a data URL
    "data:image/svg+xml;base64,#{Base64.strict_encode64(svg_content)}"
  end
end
