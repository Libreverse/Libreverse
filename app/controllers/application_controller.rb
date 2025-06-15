# frozen_string_literal: true

class ApplicationController < ActionController::Base
    include CableReady::Broadcaster
    include PasswordSecurityEnforcer
    include Loggable
    include SpamDetection
    helper_method :current_account

    # Protection from CSRF
    protect_from_forgery with: :exception

    # Global spam protection as a safety net
    before_action :global_spam_protection_check

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
        # Otherwise get account_id from session (like GraphqlController pattern)
        Current.account || begin
            account_id = session[:account_id] || request.env["rack.session"]&.[](:account_id)
            account_id ? AccountSequel.where(id: account_id).first : nil
        end
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

    # Helper methods for authentication
    def require_authentication
      return if current_account

      flash[:alert] = "You must be logged in to access this page."
      redirect_to "/login"
    end

    def require_admin
      return if current_account&.admin?

      flash[:alert] = "You must be an admin to perform that action."
      redirect_to root_path
    end

    # Helper method to get current instance domain
    def current_instance_domain
      @current_instance_domain ||= if LibreverseInstance::Application.respond_to?(:instance_domain)
          LibreverseInstance::Application.instance_domain
      else
          # Fallback during early initialization
          ENV["INSTANCE_DOMAIN"] || case Rails.env
                                    when "development"
                                      "localhost:3000"
                                    when "test"
                                      "localhost"
                                    else
                                      "localhost"
                                    end
      end
    end
    helper_method :current_instance_domain

    # Helper method to get current account's federated identifier
    def current_account_federated_id
      current_account&.federated_identifier || "@guest@#{current_instance_domain}"
    end
    helper_method :current_account_federated_id

    # Global spam protection method - acts as a safety net for forms that might bypass controller-specific protection
    def global_spam_protection_check
      return unless should_check_for_spam?
      return unless contains_invisible_captcha_fields?

      # Perform manual honeypot validation
      honeypot_key = params.keys.find { |key| key.match?(/^[a-f0-9]{8,}$/) && key != "invisible_captcha_timestamp" }
      if honeypot_key && params[honeypot_key].present?
        log_spam_attempt("honeypot", {
                           field: honeypot_key,
                           value: params[honeypot_key],
                           detection_method: "global_protection"
                         })

        flash[:alert] = "There was an error processing your request. Please try again."
        redirect_to_safe_location
        return
      end

      # Perform timestamp validation
      return if params[:invisible_captcha_timestamp].blank?

        timestamp = params[:invisible_captcha_timestamp].to_i
        current_time = Time.current.to_i
        threshold = 4 # seconds - more lenient for global check

        return unless (current_time - timestamp) < threshold

          log_spam_attempt("timestamp", {
                             timestamp: timestamp,
                             current_time: current_time,
                             threshold: threshold,
                             detection_method: "global_protection"
                           })

          flash[:alert] = "Please wait a moment before submitting the form."
          redirect_to_safe_location
          nil
    end

    # Check if we should perform global spam detection
    def should_check_for_spam?
      # Skip if controller already has invisible_captcha configured to prevent double-validation
      return false if invisible_captcha_configured?

      # Skip API endpoints
      return false if request.path.start_with?("/api/", "/graphql", "/xmlrpc")

      # Skip authentication paths (handled by RodauthController)
      return false if request.path.start_with?("/login", "/create-account", "/reset-password", "/change-password")

      # Skip non-state-changing requests
      return false unless request.post? || request.put? || request.patch?

      # Only check if this is likely a form submission
      true
    end

    # Check if current controller has invisible_captcha already configured
    def invisible_captcha_configured?
      return false unless self.class.respond_to?(:invisible_captcha_options)

      options = self.class.invisible_captcha_options
      options.present? && options[:only].present?
    end

    # Check if request contains invisible captcha fields
    def contains_invisible_captcha_fields?
      # Look for timestamp field or honeypot-style random hex fields
      return true if params[:invisible_captcha_timestamp].present?

      # Look for potential honeypot fields (random hex strings)
      params.keys.any? { |key| key.match?(/^[a-f0-9]{8,}$/) }
    end

    # Safe redirect that prevents open redirects
    def redirect_to_safe_location
      safe_path = request.referer&.start_with?(request.base_url) ? request.referer : root_path
      redirect_to safe_path
    end

    # Enhanced logging method for spam attempts
    def log_spam_attempt(spam_type, additional_data = {})
      log_data = {
        spam_type: spam_type,
        ip: request.remote_ip,
        user_agent: request.user_agent,
        path: request.path,
        method: request.method,
        timestamp: Time.current.iso8601
      }.merge(additional_data)

      Rails.logger.warn "[SPAM DETECTED] #{log_data.to_json}"

      # Could also send to monitoring service here
      # SpamMonitoringService.record_attempt(log_data) if defined?(SpamMonitoringService)
    end
end
