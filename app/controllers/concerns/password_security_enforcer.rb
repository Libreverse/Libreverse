module PasswordSecurityEnforcer
  extend ActiveSupport::Concern

  included do
    before_action :enforce_password_security
  end

  private

  # Redirects users to change password page if they have a pwned password
  def enforce_password_security
    # Early return for unauthenticated users or paths that should be exempt
    return unless rodauth.logged_in?
    return unless rodauth.session && rodauth.session[:password_pwned]
    
    # Skip check if we're already on, or being redirected to, the change password page
    return if request.path == "/change-password"
    return if response.redirect? && response.location&.end_with?("/change-password")
    
    # Skip check for assets and other non-app paths
    return if request.path.start_with?("/assets/", "/cable", "/rails/", "/packs/")
    
    # Skip for API and non-GET requests
    return if request.format.json? || request.format.xml?
    return unless request.get?

    # Capture the path the user was trying to access for later
    session[:return_to_after_password_change] ||= request.original_fullpath if request.get?
    
    # Log the redirected path for debugging
    account_identifier = rodauth.account_id.to_s rescue "unknown"
    Rails.logger.info "Enforcing password change for user #{account_identifier}, " \
                     "redirecting from #{request.path} to /change-password"
    
    # Use a direct flash message for security enforced redirects
    flash[:alert] = "Your password has been found in a data breach. You must change it before proceeding."
    redirect_to "/change-password"
  end
end 