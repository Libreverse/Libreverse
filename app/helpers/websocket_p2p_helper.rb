# frozen_string_literal: true
# shareable_constant_value: literal

module WebsocketP2pHelper
  # WebSocket P2P Frame Helper
  # Provides backwards compatible p2p_frame_tag helper method

  def p2p_frame_tag(session_id:, peer_id:, expires_in: 2.hours, config: {}, &block)
    # NOTE: expires_in kept for backwards compatibility but not used in WebSocket implementation
    # WebSocket connections don't have the same expiration concept as WebRTC
    _ = expires_in # Acknowledge parameter to avoid lint warning

    # Generate frame attributes
    frame_attributes = {
      "session-id" => session_id,
      "peer-id" => peer_id,
      "config" => config.to_json
    }

    # Create the p2p-frame custom element
    content_tag("p2p-frame", frame_attributes) do
      capture(&block) if block_given?
    end
  end

  # Alternative method name for consistency
  alias websocket_p2p_frame_tag p2p_frame_tag
end
