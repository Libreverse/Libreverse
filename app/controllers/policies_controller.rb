# frozen_string_literal: true

class PoliciesController < ApplicationController
  skip_before_action :_enforce_privacy_consent

  # Cache policy pages for 1 hour since they don't change frequently
  before_action :set_cache_headers

  DISCLAIMER = <<~HTML
    <p class="policy-disclaimer">
      This Privacy Policy and Cookie Policy are provided in English due to resource constraints.
    </p>
  HTML

  def privacy
  end

  def cookies
  end

  private

  def set_cache_headers
    # Skip cache headers in development to avoid masking application errors
    expires_in 1.hour, public: true unless Rails.env.development?
  end
end
