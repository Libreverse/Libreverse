# frozen_string_literal: true

class ConsentController < ApplicationController
    include Turbo::Streams::ActionHelper

    # Configure invisible captcha for consent forms to prevent automated abuse
    # invisible_captcha only: %i[accept decline],
    # timestamp_threshold: 1 # Very short threshold for consent

    # Skip CSRF for consent flow but maintain spam protection
    skip_before_action :verify_authenticity_token

    # GET /consent/screen (or /consent)
    def screen
        render turbo_stream: turbo_stream.morph(".consent-overlay", render_to_string("consent/screen", layout: false))
    end

    # POST /consent/accept
    def accept
        remember_opt_in = params[:remember_opt_in] == "1"

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

        if remember_opt_in
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

        logger.info("[EEA Compliance] Consent accepted for user with IP: #{request.remote_ip}")

        return_to = session.delete(:return_to) || root_path

        respond_to do |format|
            format.turbo_stream { render turbo_stream: turbo_stream.redirect_to(return_to) }
            format.html { redirect_to return_to }
        end
    end

    # POST /consent/decline
    def decline
        logger.warn("[EEA Compliance] Consent declined for user with IP: #{request.remote_ip}")

        html = <<~HTML
          <div class="consent-decline">
              <h1>Consent Required</h1>
              <p>You declined the Privacy &amp; Cookie Policy. Libreverse cannot operate without the strictly necessary cookies described in the policy. Please reconsider to continue.</p>
              <button class="btn-secondary" data-action="click->consent#showScreen">Go Back</button>
          </div>
        HTML

        render turbo_stream: turbo_stream.morph(".consent-overlay", html)
    end
end
