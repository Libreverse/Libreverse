module ApplicationCable
  class Connection < ActionCable::Connection::Base
    # Identify the connection by the authenticated account ID
    identified_by :current_account_id

    def connect
      # Add logging for the request class
      Rails.logger.debug "[ActionCable] Connection request class: #{request.class}"

      # 1. Find session_id (using existing logic)
      session_id = find_session_id
      unless session_id
        Rails.logger.warn "[ActionCable] Connection rejected: No session_id found."
        reject_unauthorized_connection
        return
      end
      Rails.logger.debug "[ActionCable] Found session_id: #{session_id}"

      # 2. Instantiate Rodauth for this request context
      rodauth = request.env["rodauth"]
      unless rodauth
        Rails.logger.error "[ActionCable] Connection rejected: Rodauth instance not found in request env."
        reject_unauthorized_connection
        return
      end

      # 3. Check authentication state
      if rodauth.logged_in?
        # Fully authenticated user
        self.current_account_id = rodauth.session_value
        Rails.logger.info "[ActionCable] Connection established and authenticated for account_id: #{current_account_id}"
      elsif allow_guest_connections? && create_guest_session(rodauth)
        # Guest user - get the account ID from the newly created guest session
        self.current_account_id = rodauth.session_value
        Rails.logger.info "[ActionCable] Connection established with guest account_id: #{current_account_id}"
      else
        # Neither authenticated nor guest allowed - reject
        Rails.logger.warn "[ActionCable] Connection rejected: Not authenticated and guest not allowed/created."
        reject_unauthorized_connection
      end
    end

    private

    # Helper method to consolidate session ID finding logic
    def find_session_id
      session_id = request.session.id
      unless session_id
        Rails.logger.debug "[ActionCable] request.session.id was nil, trying signed cookie..."
        session_key = Rails.application.config.session_options[:key]
        session_id = cookies.signed[session_key]
      end
      session_id
    end

    # Allow guest connections for non-sensitive operations
    def allow_guest_connections?
      # You can customize this logic based on your app's requirements
      # For example, you might check the origin to only allow guests from certain pages
      true
    end

    # Create a guest session if one doesn't exist
    def create_guest_session(rodauth)
      return true if rodauth.session_value # Already has a session value, no need to create

      # Direct database approach to create a guest account
      begin
        # Create a guest account directly
        username = "guest_#{SecureRandom.uuid}@example.com"
        account = Account.create!(
          username: username,
          guest: true,
          created_at: Time.current,
          updated_at: Time.current
        )

        # Now manually set the session value in rodauth
        rodauth.instance_variable_set("@account_id", account.id)
        rodauth.send(:set_session_value, :account_id, account.id)

        # Reset this value so session_value method returns the correct account id
        rodauth.instance_variable_set("@session_value", account.id)

        # Ensure we have the session value now
        success = rodauth.session_value.present?

        if success
          Rails.logger.info "[ActionCable] Successfully created guest account #{account.id} for WebSocket connection"
        else
          Rails.logger.error "[ActionCable] Failed to set session value after creating guest account"
        end

        success
      rescue StandardError => e
        Rails.logger.error "[ActionCable] Failed to create guest account: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        false
      end
    end
  end
end
