# typed: strict
# frozen_string_literal: true
# shareable_constant_value: literal

# This app primarily uses Vite for asset compilation. However, some gems still
# require Sprockets for their JavaScript/CSS assets:
#
# 1. THREDDED (forum engine)
# 2. COMFORTABLE_MEDIA_SURFER (CMS engine, aka Comfy)
#
# DO NOT use Sprockets for new assets. Everything else should go through Vite.
# This coexistence setup exists solely for gem compatibility.

Rails.application.config.after_initialize do
  next unless defined?(Sprockets)

  # Enable Sprockets alongside Vite
  Rails.application.config.assets.enabled = true
  Rails.application.config.assets.version = "1.0"

  # Thredded forum engine
  if Gem.loaded_specs.key?("thredded")
    thredded_path = Gem.loaded_specs["thredded"].full_gem_path
    Rails.application.config.assets.paths << File.join(thredded_path, "app/assets/javascripts")
    Rails.application.config.assets.paths << File.join(thredded_path, "vendor/assets/javascripts")
  end

  # Timeago.js (Thredded dependency for relative timestamps)
  if Gem.loaded_specs.key?("timeago_js")
    timeago_path = Gem.loaded_specs["timeago_js"].full_gem_path
    Rails.application.config.assets.paths << File.join(timeago_path, "assets/javascripts")
  end

  # Rails UJS from node_modules (Thredded expects rails-ujs)
  rails_ujs_path = Rails.root.join("node_modules/@rails/ujs/app/assets/javascripts")
  Rails.application.config.assets.paths << rails_ujs_path.to_s if rails_ujs_path.exist?

  # Comfortable Media Surfer (Comfy CMS)

  # Comfy's assets are auto-registered by its engine, but we ensure the paths
  # are available for sassc-rails to resolve @import statements.
  if Gem.loaded_specs.key?("comfortable_media_surfer")
    comfy_path = Gem.loaded_specs["comfortable_media_surfer"].full_gem_path
    Rails.application.config.assets.paths << File.join(comfy_path, "app/assets/stylesheets")
    Rails.application.config.assets.paths << File.join(comfy_path, "app/assets/javascripts")
  end

  # CodeMirror styles for Comfy admin (local override)
  Rails.application.config.assets.paths << Rails.root.join("vendor/assets/stylesheets").to_s

  # Precompile list
  Rails.application.config.assets.precompile += %w[
    thredded.js
    comfy/admin/cms/application.css
    comfy/admin/cms/application.js
  ]
end

# Config for sprockets and propshaft themselves

Rails.application.config.assets.integrity_hash_algorithm = "sha384"
Rails.application.config.file_watcher = ActiveSupport::EventedFileUpdateChecker
Rails.application.config.assets.unknown_asset_fallback = false
Rails.application.config.assets.digest = true
