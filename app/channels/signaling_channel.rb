# frozen_string_literal: true

# ActionCable channel for P2P WebRTC signaling
# Handles the coordination of peer connections for multiplayer experiences
class SignalingChannel < ApplicationCable::Channel
  def subscribed
    # Extract parameters from subscription
    @session_id = params[:session_id]
    @peer_id = params[:peer_id]

    # Validate required parameters
    unless @session_id.present? && @peer_id.present?
      Rails.logger.warn "[SignalingChannel] Missing required parameters: session_id=#{@session_id}, peer_id=#{@peer_id}"
      reject
      return
    end

    # Join the session stream
    stream_from "signaling_session_#{@session_id}"

    Rails.logger.info "[SignalingChannel] Peer #{@peer_id} joined session #{@session_id}"

    # Notify existing peers about the new participant
    broadcast_to_session(
      type: "Connection",
      session_id: @session_id,
      peer_id: @peer_id,
      state: "SessionJoin"
    )
  end

  def unsubscribed
    return unless @session_id && @peer_id

    Rails.logger.info "[SignalingChannel] Peer #{@peer_id} left session #{@session_id}"

    # Notify remaining peers about disconnection
    broadcast_to_session(
      type: "Connection",
      session_id: @session_id,
      peer_id: @peer_id,
      state: "PeerDisconnected"
    )
  end

  # Handle incoming signaling messages from clients
  def receive(data)
    return unless valid_message?(data)

    Rails.logger.debug "[SignalingChannel] Received message from #{@peer_id}: #{data['state']}"

    # Forward the message to all peers in the session
    broadcast_to_session(data.merge(
                           "peer_id" => @peer_id,
                           "session_id" => @session_id
                         ))
  end

  private

  def broadcast_to_session(message)
    ActionCable.server.broadcast("signaling_session_#{@session_id}", message)
  end

  def valid_message?(data)
    data.is_a?(Hash) &&
      data["type"].present? &&
      data["state"].present?
  end
end
