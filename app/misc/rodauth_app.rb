class RodauthApp < Rodauth::Rails::App
  # primary configuration
  configure RodauthMain

  # secondary configuration
  # configure RodauthAdmin, :admin

  route do |r|
    rodauth.load_memory # autologin remembered users

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
