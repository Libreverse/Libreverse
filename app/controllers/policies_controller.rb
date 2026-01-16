# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class PoliciesController < ApplicationController
  skip_before_action :_enforce_privacy_consent

  DISCLAIMER = <<~HTML
    This Privacy Policy and Cookie Policy are provided in English due to resource constraints.
  HTML

  def privacy
  end

  def cookies
  end

  helper_method :markdown
end
