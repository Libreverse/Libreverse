class ApplicationController < ActionController::Base
    include CableReady::Broadcaster
    include PasswordSecurityEnforcer
    helper_method :current_account

    before_action :disable_browser_cache, if: -> { Rails.env.development? }

  private

    def current_account
        rodauth.rails_account
    end

    def disable_browser_cache
      response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    end
end
