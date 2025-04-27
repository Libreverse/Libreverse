# frozen_string_literal: true

class ConsentsController < ApplicationController
  skip_before_action :_enforce_privacy_consent
  skip_forgery_protection only: %i[accept decline]

  layout "application"

  def show
    session[:return_to] ||= params[:return_to] || request.referer || root_path
    render template: "consent/screen", layout: "application"
  end

  def accept
    # Set secure cookie with all recommended settings
    cookies.signed[EEAMode::CONSENT_COOKIE_KEY] = {
      value: "1",
      expires: EEAMode::COMPLIANCE[:cookie_settings][:expiration].from_now,
      same_site: EEAMode::COMPLIANCE[:cookie_settings][:same_site],
      secure: if EEAMode::COMPLIANCE[:cookie_settings][:secure].is_a?(Proc)
  EEAMode::COMPLIANCE[:cookie_settings][:secure].call
              else
  EEAMode::COMPLIANCE[:cookie_settings][:secure]
              end,
      httponly: EEAMode::COMPLIANCE[:cookie_settings][:httponly]
    }

    log_info("[EEA Compliance] Consent accepted for user with IP: #{request.remote_ip}")

    if params[:remember_opt_in] == "1"
      cookies.signed[:remember_opt_in] = {
        value: "1",
        expires: 30.days.from_now,
        same_site: :strict,
        secure: Rails.application.config.force_ssl,
        httponly: true
      }
    else
      cookies.delete(:remember_opt_in)
    end

    redirect_to(session.delete(:return_to) || root_path)
  end

  def decline
    log_warn("[EEA Compliance] Consent declined for user with IP: #{request.remote_ip}")
    render inline: <<~ERB, status: :ok
      <div class="consent-decline">
        <h1>Consent Required</h1>
        <p>You declined the Privacy &amp; Cookie Policy. Libreverse cannot operate without the strictly necessary cookies described in the policy. Please reconsider to continue.</p>
        <%= button_to "Go Back", consent_path, method: :get, class: "btn-secondary" %>
      </div>
    ERB
  end
end
