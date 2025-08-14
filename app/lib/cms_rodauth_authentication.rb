# frozen_string_literal: true

# Custom authentication module for ComfortableMediaSurfer that integrates with Rodauth
module CmsRodauthAuthentication
  # This method is called by ComfortableMediaSurfer to check if the user is authenticated
  def authenticate
    # Debug: log current_account and admin status
    Rails.logger.warn "[CmsRodauthAuthentication] controller.respond_to?(:current_account): #{controller.respond_to?(:current_account)}"
    Rails.logger.warn "[CmsRodauthAuthentication] controller.current_account: #{controller.current_account.inspect}"
    if controller.respond_to?(:current_account) && controller.current_account
      account = controller.current_account
      Rails.logger.warn "[CmsRodauthAuthentication] account.admin: #{account.admin.inspect} (#{account.admin.class})"
      # Only allow admin users to access the CMS
      if account.respond_to?(:admin) && account.admin == true
        Rails.logger.warn "[CmsRodauthAuthentication] PASSED: admin access granted"
        return true
      else
        Rails.logger.warn "[CmsRodauthAuthentication] FAILED: admin check"
      end
    else
      Rails.logger.warn "[CmsRodauthAuthentication] FAILED: current_account check"
    end
    # If not authenticated or not admin, redirect to login
    controller.flash[:alert] = "You must be an admin to access the CMS."
    controller.redirect_to("/login?#{controller.request.query_string}")
    false
  end

  private

  def controller
    @controller ||= self
  end
end
