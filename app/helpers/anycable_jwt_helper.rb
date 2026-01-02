# frozen_string_literal: true

# JWT helper for AnyCable stateless authentication
module AnycableJwtHelper
  module_function
  
  def generate_token(account, session_id: nil, peer_id: nil)
      payload = {
        account_id: account&.id,
        username: account&.username,
        guest: account&.guest? || false,
        admin: account&.admin? || false,
        session_id: session_id,
        peer_id: peer_id,
        exp: Time.current.to_i + AnyCable.config.jwt_ttl,
        iat: Time.current.to_i
      }
      
      JWT.encode(payload, AnyCable.config.jwt_secret, "HS256")
    end
    
    def verify_token(token)
      return nil unless token
      
      decoded = JWT.decode(
        token, 
        AnyCable.config.jwt_secret, 
        true, 
        algorithm: "HS256"
      )
      
      decoded.first
    rescue JWT::ExpiredSignature, JWT::DecodeError
      nil
    end
    
    def current_account_from_token(token)
      payload = verify_token(token)
      return nil unless payload && payload['account_id']
      
      Account.find_by(id: payload['account_id'])
    end
    
    # Generate token for current account (including guest accounts)
    def generate_token_for_current_account(current_account, session_id: nil, peer_id: nil)
      return nil unless current_account
      
      generate_token(current_account, session_id: session_id, peer_id: peer_id)
    end
end
