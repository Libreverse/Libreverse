# frozen_string_literal: true

# Custom authentication module for ComfortableMediaSurfer that integrates with Rodauth
module CmsRodauthAuthentication
  # This method is called by ComfortableMediaSurfer to check if the user is authenticated
  def authenticate
    # Check if user is logged in and is an admin
    if controller.respond_to?(:current_account) && controller.current_account
      account = controller.current_account
      
      # Only allow admin users to access the CMS
      if account.respond_to?(:admin?) && account.admin?
        return true
      end
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
