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
end
