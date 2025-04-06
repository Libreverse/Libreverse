class RodauthApp < Rodauth::Rails::App
  # primary configuration
  configure RodauthMain

  # secondary configuration
  # configure RodauthAdmin, :admin

  route do |r|
    # Safely attempt to load memory for remembered users, but handle guest sessions
    if rodauth.respond_to?(:load_memory) && rodauth.session_value
      rodauth.load_memory # autologin remembered users
    else
      # This is a guest session or load_memory is not available
      Rails.logger.debug "Skipping remember feature for guest account: #{rodauth.session_value}"
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
