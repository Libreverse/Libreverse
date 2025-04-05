class RodauthApp < Rodauth::Rails::App
  # primary configuration
  configure RodauthMain

  # secondary configuration
  # configure RodauthAdmin, :admin

  route do |r|
    # Safely attempt to load memory for remembered users, but handle guest sessions
    begin
      rodauth.load_memory # autologin remembered users
    rescue NoMethodError => e
      # Handle case where remember feature methods fail for guest accounts
      if e.message.include?('include?') && rodauth.session_value
        # This is a guest session, we can ignore the error
        Rails.logger.debug "Skipping remember feature for guest account: #{rodauth.session_value}"
      else
        # Re-raise if it's not the specific error we're handling
        raise
      end
    end

    r.rodauth # route rodauth requests

    # ==> Authenticating requests
    # Call `rodauth.require_account` for requests that you want to
    # require authentication for. For example:
    #
    # Authenticate dashboard paths
    rodauth.require_account if r.path.start_with?("/dashboard")

    # ==> Secondary configurations
    # r.rodauth(:admin) # route admin rodauth requests
  end
end
