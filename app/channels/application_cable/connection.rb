# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    # Identify the connection by the authenticated account ID found in the session
    identified_by :current_account_id

    # P2P connection tracking
    attr_accessor :peer_id, :session_id, :connected_at

    def connect
      # Store connection timestamp for P2P
      self.connected_at = Time.current

      # Trust rodauth / rodauth-guest to manage session state (real user or guest)
      # RodauthApp middleware should have already ensured a session exists.
      self.current_account_id = find_account_id_from_session

      # Reject if no identification was possible via session
      unless current_account_id
        Rails.logger.warn "[ActionCable] Rejecting connection: No authenticated user or guest found in session."
        reject_unauthorized_connection
        return # Ensure connect method exits after rejection
      end

      # Log successful connection identified via session
      # Handle invalid session markers (negative account IDs)
      begin
      if current_account_id&.negative?
        # Reject connection so the client can clear cookies
        reject_unauthorized_connection
        return
      end

      account = AccountSequel.with_pk!(current_account_id)
        account.guest? ? "guest" : "user"
      rescue Sequel::NoMatchingRow
         Rails.logger.error "[ActionCable] Connection established but Account record not found for ID: \\#{current_account_id}"
         reject_unauthorized_connection # Reject if account doesn't exist
      end
    end

    private

    # Finds a valid account ID (real or guest) from the session store
    def find_account_id_from_session
      # AnyCable automatically parses the session cookie and makes it available in request.session
      session_data = request.session.to_h

      # --- Extract account_id directly from the session hash ---
      account_id = nil
      rodauth_session_key_name = :account_id # Default Rodauth key name (symbol)
      rodauth_session_key_string = rodauth_session_key_name.to_s # String version
      begin
        # Try to get the configured key name safely if Rodauth instance available
        # Note: request.env['rodauth'] is likely nil here, so fallback usually runs
        rodauth_instance = request.env["rodauth"]
        if rodauth_instance.respond_to?(:session_key)
           config_key = rodauth_instance.session_key
           rodauth_session_key_name = config_key if config_key.is_a?(Symbol)
           rodauth_session_key_string = config_key.to_s
        end

        # Check for string key first (seems to be what CookieStore provides)
        account_id = session_data[rodauth_session_key_string]
        # Fallback to symbol key if string key wasn't found
        account_id ||= session_data[rodauth_session_key_name]
      rescue StandardError => e
        Rails.logger.warn "[ActionCable] Error getting rodauth session key, falling back to default :account_id. Error: #{e.message}"
        # Fallback access trying both string and symbol
        account_id = session_data["account_id"] || session_data[:account_id]
      end
      # -------------------------------------------------------

      if account_id
         verified_account = AccountSequel.where(id: account_id).first
         unless verified_account
            Rails.logger.warn "[ActionCable] Account ID '\\#{account_id}' found in session does not exist in DB. Ignoring."
            return nil
         end
         account_id # Return the verified ID
      else
         Rails.logger.warn "[ActionCable] No account_id found in session hash. Session data: #{session_data.inspect}"
         nil
      end
    rescue StandardError => e
      Rails.logger.error "[ActionCable] Error during session processing: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      nil
    end

    # --- REMOVED create_guest_account ---
    # --- REMOVED allow_guest_connections? ---
  end
end
