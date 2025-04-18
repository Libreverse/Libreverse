# frozen_string_literal: true

# SEO Configuration
# Load SEO settings for the current environment and prepare helper methods.
seo_config_raw = YAML.load_file(Rails.root.join("config/seo_config.yml"), aliases: true)[Rails.env]
seo_config_resolved = seo_config_raw.dup
# Store resolved config for runtime lookup
SEO_CONFIG = seo_config_resolved

Rails.application.config.to_prepare do
  ApplicationHelper.module_eval do
    # Resolve asset paths: '@' for images/, '~/' for explicit paths
    def seo_asset_path(path)
      if path.is_a?(String)
        if path.start_with?("@")
          vite_asset_path("images/#{path.sub('@', '')}")
        elsif path.start_with?("~/")
          vite_asset_path(path)
        else
          path
        end
      else
        path
      end
    end

    # Lookup SEO config value, resolving assets when needed
    def seo_config_with_assets(key)
      value = SEO_CONFIG[key.to_s]
      if %w[preview_image shortcut_icon apple_touch_icon mask_icon].include?(key.to_s)
        seo_asset_path(value)
      else
        value
      end
    end
  end
end
