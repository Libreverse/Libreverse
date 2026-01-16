# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

Rails.application.configure do
  # SmartAssets configuration
  #
  # SmartAssets is a Rack Middleware for Rails that enables delivery of non-digest assets
  # when using the default asset pipeline.
  #
  # It solves the problem of production environment requests for assets (eg: `application.css`)
  # returning a 404 because they do not contain a digest.

  next unless config.respond_to?(:smart_assets)

  config.smart_assets.cache_control = "public,max-age=60"

  # The default is disabled for `development` and enabled for all other environments.
  # config.smart_assets.serve_non_digest_assets = false
end
