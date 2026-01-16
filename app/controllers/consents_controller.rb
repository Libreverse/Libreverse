# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

class ConsentsController < ApplicationController
  skip_before_action :_enforce_privacy_consent
  skip_forgery_protection only: %i[accept decline]

  layout "application"

  def show
    session[:return_to] ||= params[:return_to] || request.referer || root_path
    render template: "consent/screen", layout: "application"
  end

  def accept
    # No longer used; handled by ConsentReflex
    head :not_found
  end

  def decline
    # No longer used; handled by ConsentReflex
    head :not_found
  end
end
