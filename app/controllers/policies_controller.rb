# frozen_string_literal: true

class PoliciesController < ApplicationController
  skip_before_action :_enforce_privacy_consent

  DISCLAIMER = <<~HTML
    <p class="policy-disclaimer">
      This Privacy Policy and Cookie Policy are provided in English due to resource constraints.
    </p>
  HTML

  def privacy
  end

  def cookies
  end
end
