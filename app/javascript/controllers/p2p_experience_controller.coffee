import { P2pController } from "p2p"

export default class extends P2pController
  @targets = ["iframe", "status", "participantsList"]
  @values = {
    experienceId: String,
    sessionId: String,
  }

  connect: ->
    super()
    @setupIframeMessaging()
    @updateStatus "Connecting to peers..."

  # P2P event handlers
  p2pNegotiating: ->
    @updateStatus "Negotiating connection..."

  p2pConnecting: ->
    @updateStatus "Connecting to peers..."

  p2pConnected: ->
    @updateStatus "Connected! You are #{if @iamHost then "hosting" else "participating in"} this session."
    @broadcastToIframe {
      type: "p2p-status",
      connected: true,
      isHost: @iamHost,
      peerId: @peerId,
      hostPeerId: @hostPeerId,
    }

  p2pDisconnected: ->
    @updateStatus "Disconnected from peers"
    @broadcastToIframe {
      type: "p2p-status",
      connected: false,
    }

  p2pClosed: ->
    @updateStatus "Session ended"

  p2pError: ->
    @updateStatus "Connection error occurred"

  # Handle messages from P2P network
  p2pReceivedMessage: (message) ->
    switch message.type
      when "Data"
        # Forward data messages to the iframe
        @broadcastToIframe {
          type: "p2p-message",
          senderId: message.senderId,
          data: message.data,
        }
      when "Data.Connection.State"
        # Update participants list
        @updateParticipants message.data
        @broadcastToIframe {
          type: "p2p-participants",
          participants: message.data,
        }

  # Setup communication with the iframe
  setupIframeMessaging: ->
    globalThis.addEventListener "message", (event) =>
      # Verify origin is from our iframe
      return unless event.source is @iframeTarget.contentWindow

      { type, data } = event.data

      switch type
        when "p2p-send"
          # Forward message from iframe to P2P network
          @p2pSendMessage data
        when "iframe-ready"
          # Iframe is loaded and ready for P2P
          @onIframeReady()

  # Send message to iframe
  broadcastToIframe: (message) ->
    if @iframeTarget and @iframeTarget.contentWindow
      @iframeTarget.contentWindow.postMessage message, "*"

  # Called when iframe signals it's ready
  onIframeReady: ->
    # Send initial P2P state to iframe
    @broadcastToIframe {
      type: "p2p-init",
      sessionId: @sessionIdValue,
      experienceId: @experienceIdValue,
      peerId: @peerId,
      isHost: @iamHost,
    }

  # Update status display
  updateStatus: (message) ->
    if @hasStatusTarget
      @statusTarget.textContent = message

  # Update participants list
  updateParticipants: (participantStates) ->
    return unless @hasParticipantsListTarget

    participants = Object.entries(participantStates).map ([peerId, state]) =>
      {
        id: peerId,
        state: state,
        isHost: peerId is @hostPeerId,
        isMe: peerId is @peerId,
      }

    @participantsListTarget.innerHTML = participants.map((p) ->
      """
      <li class="participant #{if p.isHost then "host" else ""} #{if p.isMe then "me" else ""}">
        #{if p.isHost then "👑 " else ""}#{if p.isMe then "You" else "Peer #{p.id.slice(-6)}"}
        <span class="status">#{p.state}</span>
      </li>
      """
    ).join("")

  # Actions for user controls
  startSession: (event) ->
    event.preventDefault()
    # Session starts automatically when P2P connects
    @updateStatus "Starting session..."

  leaveSession: (event) ->
    event.preventDefault()
    globalThis.location.href = "/experiences/#{@experienceIdValue}"
