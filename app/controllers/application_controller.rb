class ApplicationController < ActionController::Base
    include CableReady::Broadcaster
    helper_method :current_account

  private

    def current_account
        rodauth.rails_account
    end
end
