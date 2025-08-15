# frozen_string_literal: true

class WebsocketP2pChannel < ApplicationCable::Channel
  # Alpha: stripped down to peer roster + generic messaging.

  def subscribed
    @session_id = params[:session_id]
    @peer_id = params[:peer_id]

    Rails.logger.info "[WebsocketP2pChannel] Peer #{@peer_id} joining session #{@session_id}"

    # Validate parameters
    reject unless @session_id.present? && @peer_id.present?

    # Join session room
    stream_from "websocket_p2p_session_#{@session_id}"

    # Store peer info in connection
    connection.peer_id = @peer_id
    connection.session_id = @session_id

    # Announce peer joining
    broadcast_to_session({
                           type: "peer_joined",
                           peer_id: @peer_id,
                           timestamp: Time.current.to_i
                         })

    # Send current peers list to new peer
    send_peers_list
  end

  def unsubscribed
    return unless @session_id && @peer_id

    Rails.logger.info "[WebsocketP2pChannel] Peer #{@peer_id} leaving session #{@session_id}"

    # Announce peer leaving
    broadcast_to_session({
                           type: "peer_left",
                           peer_id: @peer_id,
                           timestamp: Time.current.to_i
                         })
  end

  # Handle incoming P2P messages
  def receive(data)
    return unless valid_message?(data)

    case data["type"]
    when "message" then handle_p2p_message(data)
    when "heartbeat" then handle_heartbeat(data)
    when "request_peers" then send_peers_list
    else
      Rails.logger.warn "[WebsocketP2pChannel] Unknown message type: #{data['type']}"
    end
  end

  private

  def handle_p2p_message(data)
    message = {
      type: "message",
      from_peer_id: @peer_id,
      to_peer_id: data["to_peer_id"], # nil for broadcast
      data: data["data"],
      timestamp: Time.current.to_i
    }

    if data["to_peer_id"].present?
      # Direct message to specific peer
      broadcast_to_peer(data["to_peer_id"], message)
    else
      # Broadcast to all peers except sender
      broadcast_to_session(message, except: @peer_id)
    end
  end

  def handle_heartbeat(_data)
    # Respond with heartbeat ack
    transmit({
               type: "heartbeat_ack",
               timestamp: Time.current.to_i
             })
  end

  def send_peers_list
    peers = session_peers

    transmit({
               type: "peers_list",
               peers: peers,
               your_peer_id: @peer_id,
               timestamp: Time.current.to_i
             })
  end

  def session_peers
    # Get all connections for this session
    connections = ActionCable.server.connections.select do |conn|
      conn.respond_to?(:session_id) && conn.session_id == @session_id
    end

    connections.map do |conn|
      {
        peer_id: conn.peer_id,
        connected_at: conn.connected_at&.to_i || Time.current.to_i
      }
    end
  end

  def broadcast_to_session(message, except: nil)
    # Broadcast to all peers in session
    peers = session_peers

    peers.each do |peer|
      next if except && peer[:peer_id] == except

      broadcast_to_peer(peer[:peer_id], message)
    end
  end

  def broadcast_to_peer(peer_id, message)
    ActionCable.server.broadcast(
      "websocket_p2p_peer_#{peer_id}",
      message
    )
  end

  def valid_message?(data)
    data.is_a?(Hash) && data["type"].present?
  end
end
