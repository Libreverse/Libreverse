# frozen_string_literal: true

# ================================================================================
# Sprockets configuration for Thredded JavaScript ONLY
# ================================================================================
#
# This is an ISOLATED Sprockets setup specifically for Thredded's forum JavaScript.
# Thredded uses Sprockets directives (//= require) extensively and cannot be easily
# ported to Vite/ESM without rewriting the gem's JS.
#
# DO NOT use this as a pattern for other assets - everything else should go through
# Vite. This exists solely because Thredded's JS architecture requires Sprockets.
#
# The compiled output goes to public/assets/thredded.js and is loaded via a simple
# script tag in the layout.
# ================================================================================

Rails.application.config.after_initialize do
  next unless defined?(Sprockets)

  # Configure Sprockets asset paths for Thredded
  Rails.application.config.assets.enabled = true
  Rails.application.config.assets.version = "1.0"

  # Add Thredded gem paths
  if Gem.loaded_specs.key?("thredded")
    thredded_path = Gem.loaded_specs["thredded"].full_gem_path
    Rails.application.config.assets.paths << File.join(thredded_path, "app/assets/javascripts")
    Rails.application.config.assets.paths << File.join(thredded_path, "vendor/assets/javascripts")
  end

  # Add timeago_js gem paths (thredded dependency)
  if Gem.loaded_specs.key?("timeago_js")
    timeago_path = Gem.loaded_specs["timeago_js"].full_gem_path
    Rails.application.config.assets.paths << File.join(timeago_path, "assets/javascripts")
  end

  # Add rails-ujs from node_modules (thredded expects rails-ujs)
  rails_ujs_path = Rails.root.join("node_modules/@rails/ujs/app/assets/javascripts")
  Rails.application.config.assets.paths << rails_ujs_path.to_s if rails_ujs_path.exist?

  # Precompile the thredded bundle
  Rails.application.config.assets.precompile += %w[thredded.js]
end
