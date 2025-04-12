class ApplicationController < ActionController::Base
    include CableReady::Broadcaster
    include PasswordSecurityEnforcer
    include Loggable
    helper_method :current_account

    before_action :disable_browser_cache, if: -> { Rails.env.development? }
    before_action :initialize_guest_preferences
    before_action :log_request_info
    after_action :log_response_info

    helper_method :tutorial_dismissed?

  private

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
end
