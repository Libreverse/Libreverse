class ApplicationController < ActionController::Base
    include CableReady::Broadcaster
    include PasswordSecurityEnforcer
    helper_method :current_account

    before_action :disable_browser_cache, if: -> { Rails.env.development? }
    before_action :initialize_drawer_state
    before_action :initialize_scroll_state

    helper_method :tutorial_dismissed?

  private

    def current_account
        rodauth.rails_account
    end

    def tutorial_dismissed?(key)
      # If logged in, check database
      if rodauth.logged_in?
        UserPreference.dismissed?(current_account.id, key)
      else
        # For guests, check session
        session[:dismissed_items]&.include?(key)
      end
    end

    def disable_browser_cache
      response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    end

    def initialize_drawer_state
      session[:drawer_expanded] = false if session[:drawer_expanded].nil?
    end

    def initialize_scroll_state
      # Enable scrolling by default (no_scroll = false)
      @no_scroll = false unless defined?(@no_scroll)
    end
end
