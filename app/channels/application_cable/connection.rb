module ApplicationCable
  class Connection < ActionCable::Connection::Base
    # Identify the connection by the session ID itself
    identified_by :session_id

    def connect
      # Attempt 1: Try the request session ID first (might be populated by middleware)
      self.session_id = request.session.id
      
      # Attempt 2: Fallback to signed cookie if request.session.id is nil
      unless self.session_id
        Rails.logger.warn "ActionCable: request.session.id was nil, trying signed cookie..."
        session_key = Rails.application.config.session_options[:key]
        self.session_id = cookies.signed[session_key]
      end
      
      # Now reject only if *both* methods failed to find an ID
      reject_unauthorized_connection unless session_id
      
      Rails.logger.info "ActionCable Connection established with session_id: #{session_id}"
    end
    
    # We no longer need find_verified_account here, 
    # the session store will be loaded based on session_id for the Reflex
  end
end
