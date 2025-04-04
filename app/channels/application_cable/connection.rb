module ApplicationCable
  class Connection < ActionCable::Connection::Base
    # Identify the connection by the authenticated account ID
    identified_by :current_account_id

    def connect
      # 1. Find session_id (using existing logic)
      session_id = find_session_id
      unless session_id
        Rails.logger.warn "[ActionCable] Connection rejected: No session_id found."
        reject_unauthorized_connection
        return
      end
      Rails.logger.debug "[ActionCable] Found session_id: #{session_id}"

      # 2. Instantiate Rodauth for this request context
      # We need the request environment to initialize Rodauth
      # Note: This assumes RodauthApp is your configured Rack app instance
      # You might need to adjust how you get the Rodauth instance if setup differs.
      # rodauth = RodauthApp.rodauth(request.env)
      # Simpler approach: Access rodauth instance associated with the request
      rodauth = request.env["rodauth"]
      unless rodauth
        Rails.logger.error "[ActionCable] Connection rejected: Rodauth instance not found in request env."
        reject_unauthorized_connection
        return
      end

      # 3. Attempt to load session and verify authentication
      # Manually loading might be complex. Leverage Rodauth's session loading if possible.
      # Rodauth usually loads based on the session cookie during its middleware run.
      # Let's check if it has already loaded based on the cookie passed with the WS request.
      
      # Check if rodauth recognizes the session as logged in
      # This relies on warden/rodauth middleware having processed the WS upgrade request
      if rodauth.logged_in?
        self.current_account_id = rodauth.session_value
        Rails.logger.info "[ActionCable] Connection established and authenticated for account_id: #{current_account_id}"
      else
        Rails.logger.warn "[ActionCable] Connection rejected: Rodauth session not authenticated for session_id: #{session_id}."
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
  end
end
