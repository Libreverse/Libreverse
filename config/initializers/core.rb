# frozen_string_literal: true

# Core Application Configuration
# This file contains essential application initializations:
# - Bootsnap performance optimization
# - Inflection rules
# - Error tracking (Sentry)
# - SEO configuration

# ===== Rodauth Base Configuration =====
Rodauth::Rails.configure do |config|
  config.app = "RodauthApp"
end

# ===== Bootsnap Performance Optimization =====
require "bootsnap"
env = ENV["RAILS_ENV"] || "development"
Bootsnap.setup(
  cache_dir: "tmp/cache", # Path to your cache
  ignore_directories: [ "node_modules" ], # Directory names to skip.
  development_mode: env == "development", # Current working environment, e.g. RACK_ENV, RAILS_ENV, etc
  load_path_cache: true, # Optimize the LOAD_PATH with a cache
  compile_cache_iseq: true,                 # Compile Ruby code into ISeq cache, breaks coverage reporting.
  compile_cache_yaml: true,                 # Compile YAML into a cache
  compile_cache_json: true,                 # Compile JSON into a cache
  readonly: true # Use the caches but don't update them on miss or stale entries.
)

# ===== Inflection Rules =====
# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, "\\1en"
#   inflect.singular /^(ox)en/i, "\\1"
#   inflect.irregular "person", "people"
#   inflect.uncountable %w( fish sheep )
# end

# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.acronym "RESTful"
# end

# ===== Error Tracking (Sentry) =====
Sentry.init do |config|
  config.dsn =
    "https://3ff68d31dcdf415b8904a05b75fdc7b1@glitchtip-cs40w800ggw0gs0k804skcc0.geor.me/7"
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
end

# ===== SEO Configuration =====
# Load SEO configuration
seo_config_raw = YAML.load_file(Rails.root.join("config/seo_config.yml"), aliases: true)[Rails.env]

# We need to resolve Vite asset paths, but we can't directly use the helpers in the initializer
# Instead, we'll modify the config to store the asset references with special prefixes
# and then add helper methods to ApplicationHelper to resolve them at runtime
seo_config_resolved = seo_config_raw.dup

# For asset keys, we just ensure they maintain their special prefixes
# These will be resolved at runtime by the appropriate view helpers
# @ prefix is used for assets in the images/ directory
# ~/ prefix is used for assets with explicit paths

# Set the final config - the actual path resolution will happen at runtime
SEO_CONFIG = seo_config_resolved

# Add method to ApplicationHelper for resolving asset paths
Rails.application.config.to_prepare do
  ApplicationHelper.module_eval do
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

    # Convenience method to get SEO config with asset path resolution
    def seo_config_with_assets(key)
      value = SEO_CONFIG[key.to_s]
      # Special handling for asset keys
      if %w[preview_image shortcut_icon apple_touch_icon mask_icon].include?(key.to_s)
        seo_asset_path(value)
      else
        value
      end
    end
  end
end
