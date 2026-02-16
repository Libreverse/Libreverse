# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

class ConsentController < ApplicationController
    include Turbo::Streams::ActionHelper

    # Configure invisible captcha for consent forms to prevent automated abuse
    # invisible_captcha only: %i[accept decline],
    # timestamp_threshold: 1 # Very short threshold for consent

    # Skip CSRF for consent flow but maintain spam protection
    skip_before_action :verify_authenticity_token

    # Add rate limiting as alternative protection
    before_action :rate_limit_consent_actions, only: %i[accept decline]

    # GET /consent/screen (or /consent)
    def screen
        render turbo_stream: turbo_stream.morph(".consent-overlay", render_to_string("consent/screen", layout: false))
    end

    def accept
        session[:consent_given] = true
        session[:consent_timestamp] = Time.current
        redirect_to root_path, notice: "Thank you for accepting"
    end

    def decline
        session[:consent_given] = false
        session[:consent_timestamp] = Time.current
        redirect_to root_path, notice: "You have declined consent"
    end

  private

    def rate_limit_consent_actions
        # Rate limit consent actions to prevent abuse (max 10 per minute)
        key = "consent_#{request.remote_ip}"
        current_count = Rails.cache.read(key) || 0

        if current_count >= 10
            render json: { error: "Too many consent requests" }, status: :too_many_requests
            return
        end

        Rails.cache.write(key, current_count + 1, expires_in: 1.minute)
    end
end
