class RodauthController < ApplicationController
  # Used by Rodauth for rendering views, CSRF protection, running any
  # registered action callbacks and rescue handlers, instrumentation etc.

  # Controller callbacks and rescue handlers will run around Rodauth endpoints.
  # before_action :verify_captcha, only: :login, if: -> { request.post? }
  # rescue_from("SomeError") { |exception| ... }

  # Layout can be changed for all Rodauth pages or only certain pages.
  # layout "authentication"
  # layout -> do
  #   case rodauth.current_route
  #   when :login, :create_account, :verify_account, :verify_account_resend,
  #        :reset_password, :reset_password_request
  #     "authentication"
  #   else
  #     "application"
  #   end
  # end

  before_action :log_rodauth_action
  before_action :set_request

  def log_rodauth_action
    Rails.logger.info "DEBUG: [RodauthController] Action #{action_name} triggered"
  end

  private

  def set_request
    @request = request
  end
end
