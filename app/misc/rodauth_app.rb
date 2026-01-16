# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class RodauthApp < Rodauth::Rails::App
  configure RodauthMain

  route do |r|
    # Handle "remember me" logic first.
    if rodauth.respond_to?(:load_memory)
      # Case 1: Not a guest session - attempt standard user remember.
      if !rodauth.guest_logged_in?
        begin
          rodauth.load_memory
        rescue StandardError => e
          Rails.logger.error "[RodauthApp] Error during load_memory (non-guest): #{e.message}"
        end
      # Case 2: It IS a guest session - ONLY try loading memory if the remember cookie key exists in the request.
      elsif request.cookies[rodauth.remember_cookie_key].present? # Check cookie presence directly
        begin
          rodauth.load_memory # Let load_memory handle remembering the guest
        rescue StandardError => e
          Rails.logger.error "[RodauthApp] Error during load_memory (guest with cookie): #{e.message}"
        end
      # Case 3: Guest session without remember cookie.
      else
      end
    end

    # After attempting to load a remembered session, ensure a session exists.
    # This handles both regular requests and ActionCable connections.
    if rodauth.logged_in?
      # If already logged in (user or existing guest from load_memory/previous step)
    else
      begin
        # Log secret key base hash *before* potentially creating a guest session
        # Important for debugging potential session key rotation issues.
        require "digest"
        # Secret key hash logging removed for security

        rodauth.allow_guest # Create guest session if none exists
      rescue StandardError => e
        Rails.logger.error "[RodauthApp] Error during allow_guest for path '#{r.path}': #{e.message}"
        # Consider implications: should the request proceed without a session?
        # Depending on the error, maybe return a specific error response.
      end
    end

    # Enforce session integrity for authenticated sessions.
    if rodauth.logged_in?
      # Keep sessions up to date and valid across devices/browsers.
      rodauth.check_active_session if rodauth.respond_to?(:check_active_session)
      rodauth.check_single_session if rodauth.respond_to?(:check_single_session)
      rodauth.update_last_activity if rodauth.respond_to?(:update_last_activity)
    end

    # Route rodauth internal requests first (e.g., POST /login, GET /create-account).
    r.rodauth

    # ==> Path-Specific Authentication/Authorization
    # Example for dashboard paths:
    if r.path.start_with?("/dashboard")
      # 1. Require an account (user or guest).
      rodauth.require_account

      # Dashboard is accessible to both guests and regular users - no additional restrictions
    end

    # Add logic for other specific paths here...

    # ==> Secondary configurations (if any)
    # r.rodauth(:admin) # route admin rodauth requests
  end
end
