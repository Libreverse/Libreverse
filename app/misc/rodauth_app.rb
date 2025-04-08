class RodauthApp < Rodauth::Rails::App
  # primary configuration
  configure RodauthMain

  # secondary configuration
  # configure RodauthAdmin, :admin

  route do |r|
    # Handle "remember me" logic, considering guest sessions.
    if rodauth.respond_to?(:load_memory)
      # Only attempt load_memory if it's NOT a guest session according to rodauth-guest,
      # OR if it IS a guest session but happens to have a remember cookie value.
      # This prevents internal errors in load_memory/logged_in_via_remember_key?
      # when called for guest sessions without a corresponding remember token.
      if !rodauth.guest_logged_in? || rodauth.logged_in_remember_key_value
        begin
          rodauth.load_memory # autologin remembered users
        rescue => e
          # Log errors during the actual load_memory call
          Rails.logger.error "[RodauthApp] Error during load_memory: #{e.message}"
        end
      else
        # It's a guest session without a remember cookie value, skip load_memory.
        Rails.logger.debug "[RodauthApp] Guest session without remember cookie. Skipping load_memory."
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
