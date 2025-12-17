# frozen_string_literal: true
# shareable_constant_value: literal

# Cookie and Session Security Configuration
Rails.application.config.action_dispatch.cookies_serializer = :json
Rails.application.config.action_dispatch.signed_cookie_digest = "SHA256"
Rails.application.config.action_dispatch.cookies_same_site_protection = :strict
Rails.application.config.action_dispatch.use_authenticated_cookie_encryption = true
