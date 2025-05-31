# frozen_string_literal: true

class ApplicationController < ActionController::Base
    include CableReady::Broadcaster
    include PasswordSecurityEnforcer
    include Loggable
    include SpamDetection
    helper_method :current_account

    before_action :disable_browser_cache, if: -> { Rails.env.development? }
    before_action :initialize_guest_preferences
    before_action :log_request_info
    after_action :log_response_info
    after_action :set_compliance_headers, if: -> { EEAMode.enabled? }
    before_action :set_current_ip
    before_action :set_locale

    helper_method :tutorial_dismissed?, :consent_given?, :consent_path

  private

    def set_compliance_headers
      response.headers["X-Privacy-Policy"] = privacy_policy_path
      response.headers["X-Cookie-Policy"] = cookie_policy_path
      response.headers["X-Consent-Required"] = (!consent_given?).to_s
      response.headers["X-Consent-Status"] = consent_given? ? "accepted" : "pending"
    end

    def current_account
        # Use Current.account if available (set by ApplicationReflex)
        # Otherwise fallback to rodauth.rails_account (for standard controllers)
        Current.account || rodauth.rails_account
    end

    def tutorial_dismissed?(key)
      # Always check UserPreference now
      current_account ? UserPreference.dismissed?(current_account.id, key) : false
      # Removed session check
    end

    def disable_browser_cache
      response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    end

    # Initializes default preferences for guests if not already set
    def initialize_guest_preferences
      # Ensure this runs only if we have a current_account (guest or user)
      return unless current_account

      # Check/set drawer state only if it's a guest account
      return unless current_account.guest?

        # Use UserPreference.set which handles checking existence
        UserPreference.set(current_account.id, :drawer_expanded, false)
      # Add other guest-specific preference initializations here if needed

      # Removed session initialization
    end

    def log_request_info
      log_info("Request started: #{request.method} #{request.fullpath}")
      log_debug("Request params: #{request.filtered_parameters.inspect}")
      log_debug("User agent: #{request.user_agent}")
    end

    def log_response_info
      log_info("Response completed: #{response.status}")
    end

    def set_current_ip
      Current.real_ip = request.env["remote_ip_original"] || request.remote_ip
      Current.ip = request.remote_ip
    end

    def set_locale
      I18n.locale =
        if current_account && (user_pref = UserPreference.get(current_account.id, "locale")).present?
          user_pref
        else
          extract_locale_from_accept_language_header || session[:locale] || I18n.default_locale
        end
    end

    def extract_locale_from_accept_language_header
      return unless request.headers["Accept-Language"]

      accepted = request.headers["Accept-Language"].scan(/[a-z]{2}(?=(-|;|,|$))/i).flatten.map(&:downcase)
      available = I18n.available_locales.map(&:to_s)
      accepted.find { |lang| available.include?(lang) }
    end
end
