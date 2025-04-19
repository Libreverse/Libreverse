# frozen_string_literal: true

class RodauthApp < Rodauth::Rails::App
  configure RodauthMain

  route do |r|
    # Handle "remember me" logic first.
    if rodauth.respond_to?(:load_memory)
      # Case 1: Not a guest session - attempt standard user remember.
      if !rodauth.guest_logged_in?
        begin
          Rails.logger.debug "[RodauthApp] Not a guest session, attempting load_memory."
          rodauth.load_memory
        rescue StandardError => e
          Rails.logger.error "[RodauthApp] Error during load_memory (non-guest): #{e.message}"
        end
      # Case 2: It IS a guest session - ONLY try loading memory if the remember cookie key exists in the request.
      elsif request.cookies[rodauth.remember_cookie_key].present? # Check cookie presence directly
        begin
          Rails.logger.debug "[RodauthApp] Guest session with remember cookie key found in request, attempting load_memory."
          rodauth.load_memory # Let load_memory handle remembering the guest
        rescue StandardError => e
          Rails.logger.error "[RodauthApp] Error during load_memory (guest with cookie): #{e.message}"
        end
      # Case 3: Guest session without remember cookie.
      else
        Rails.logger.debug "[RodauthApp] Guest session without remember cookie. Skipping load_memory."
      end
    end

    # After attempting to load a remembered session, ensure a session exists.
    # This handles both regular requests and ActionCable connections.
    if rodauth.logged_in?
      # If already logged in (user or existing guest from load_memory/previous step)
      account_type = rodauth.guest_logged_in? ? "Guest" : "User"
      Rails.logger.debug "[RodauthApp] #{account_type} session already active (ID: #{begin
                                                                                       rodauth.session_value
      rescue StandardError
                                                                                       'N/A'
      end}) for path '#{r.path}'. Skipping allow_guest."
    else
      begin
        # Log secret key base hash *before* potentially creating a guest session
        # Important for debugging potential session key rotation issues.
        require "digest"
        # Secret key hash logging removed for security

        Rails.logger.debug "[RodauthApp] No session (user/guest) found for path '#{r.path}'. Calling allow_guest."
        rodauth.allow_guest # Create guest session if none exists

        # Log confirmation if a guest session was indeed created/confirmed
        if rodauth.guest_logged_in?
          Rails.logger.info "[RodauthApp] Guest session ensured (ID: #{begin
                                                                         rodauth.session_value
          rescue StandardError
                                                                         'N/A'
          end}) for path '#{r.path}'."
        else
          # Log if allow_guest didn't result in a guest session (should be rare)
          Rails.logger.warn "[RodauthApp] allow_guest called for '#{r.path}', but guest_logged_in? is still false."
        end
      rescue StandardError => e
        Rails.logger.error "[RodauthApp] Error during allow_guest for path '#{r.path}': #{e.message}"
        # Consider implications: should the request proceed without a session?
        # Depending on the error, maybe return a specific error response.
      end
    end

    # Route rodauth internal requests first (e.g., POST /login, GET /create-account).
    r.rodauth

    # ==> Path-Specific Authentication/Authorization
    # Example for dashboard paths:
    if r.path.start_with?("/dashboard")
      # 1. Require an account (user or guest).
      Rails.logger.debug "[RodauthApp] Checking /dashboard: rodauth.logged_in? = #{rodauth.logged_in?}, rodauth.guest_logged_in? = #{rodauth.guest_logged_in?}"
      rodauth.require_account
      Rails.logger.debug "[RodauthApp] Called require_account for /dashboard. State after: logged_in?=#{rodauth.logged_in?}, guest?=#{rodauth.guest_logged_in?}"

      # 2. Redirect if it's a guest account.
      if rodauth.guest_logged_in?
        Rails.logger.warn "[RodauthApp] Guest account access attempt to /dashboard denied. Redirecting to login."
        rodauth.flash[:error] = "Please log in with a registered account to access the dashboard."
        r.redirect rodauth.login_path
      else
        # Log why we think it's NOT a guest
        Rails.logger.debug "[RodauthApp] Path /dashboard continuing: Not identified as guest. Account ID: #{begin
                                                                                                              rodauth.session_value
        rescue StandardError
                                                                                                              'N/A'
        end}"
      end
    end

    # Add logic for other specific paths here...

    # ==> Secondary configurations (if any)
    # r.rodauth(:admin) # route admin rodauth requests
  end
end
