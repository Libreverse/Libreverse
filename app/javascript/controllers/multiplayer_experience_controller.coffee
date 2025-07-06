import { P2pController } from "p2p"

export default class extends P2pController
  @values = {
    sessionId: String,
    peerId: String,
  }

  connect: ->
    super() # Call parent P2pController connect

    @iframe = document.querySelector "#experience-iframe"
    @statusIndicator = document.querySelector "#status-indicator"
    @peerList = document.querySelector "#peer-list"

    # Bind the message handler for removal later
    @boundHandleIframeMessage = @handleIframeMessage.bind @

    # Listen for messages from the iframe
    window.addEventListener "message", @boundHandleIframeMessage

    # Wait for iframe to load then initialize
    if @iframe.contentDocument?.readyState is "complete"
      @initializeIframe()
    else
      @iframe.addEventListener "load", => @initializeIframe()

  disconnect: ->
    window.removeEventListener "message", @boundHandleIframeMessage

  # P2P Connection Event Handlers
  p2pNegotiating: ->
    console.log "P2P Negotiating..."
    @updateStatus "negotiating", "Connecting to peers..."

  p2pConnecting: ->
    console.log "P2P Connecting..."
    @updateStatus "connecting", "Establishing connection..."

  p2pConnected: ->
    console.log "P2P Connected!"
    @updateStatus "connected", "Connected to multiplayer session"

    # Notify iframe that P2P is connected
    @sendToIframe "p2p-status", {
      connected: true,
      isHost: @iamHost,
      peerId: @peerId,
    }

  p2pDisconnected: ->
    console.log "P2P Disconnected"
    @updateStatus "disconnected", "Disconnected from peers"

    # Notify iframe about disconnection
    @sendToIframe "p2p-status", {
      connected: false,
      peerId: @peerId,
    }

  p2pClosed: ->
    console.log "P2P Closed"
    @updateStatus "disconnected", "Connection closed"

  p2pError: ->
    console.log "P2P Error"
    @updateStatus "disconnected", "Connection error"

  # Handle messages from other peers
  p2pReceivedMessage: (message) ->
    switch message.type
      when "Data"
        # Forward peer messages to iframe
        @sendToIframe "p2p-message", {
          senderId: message.senderId,
          data: message.data,
        }
      when "Data.Connection.State"
        # Update peer list and notify iframe
        @updatePeerList message.data
        @sendToIframe "p2p-participants", {
          participants: message.data,
        }
      else
        console.log "Unknown P2P message type:", message.type

  # Handle messages from the iframe experience
  handleIframeMessage: (event) ->
    # Only accept messages from our iframe
    return unless event.source is @iframe.contentWindow

    { type, data } = event.data

    switch type
      when "iframe-ready"
        console.log "Iframe ready for P2P"
        @initializeIframe()
      when "p2p-send"
        # Forward message from iframe to other peers
        if @p2pFrame and @p2pFrame.peer
          @p2pSendMessage data
      else
        console.log "Unknown iframe message type:", type

  # Send message to iframe
  sendToIframe: (type, data) ->
    if @iframe and @iframe.contentWindow
      @iframe.contentWindow.postMessage { type, data }, "*"

  # Initialize P2P connection in iframe
  initializeIframe: ->
    @sendToIframe "p2p-init", {
      peerId: @peerIdValue,
      sessionId: @sessionIdValue,
      isHost: @iamHost or false,
      connected: false,
    }

  # Update connection status display
  updateStatus: (status, message) ->
    if @statusIndicator
      # Remove all status classes
      @statusIndicator.className = "status-indicator"
      # Add current status class
      @statusIndicator.classList.add status

      # Update status text
      icon = @getStatusIcon status
      @statusIndicator.innerHTML = "#{icon} #{message}"

  # Update the list of connected peers
  updatePeerList: (participants) ->
    return unless @peerList

    # Clear current list except for self
    selfItem = @peerList.querySelector "li"
    @peerList.innerHTML = ""
    if selfItem
      @peerList.append selfItem

    # Add other peers
    for peerId, state of participants
      if peerId isnt @peerIdValue
        li = document.createElement "li"
        li.innerHTML = """
          <span class="peer-id">#{peerId}</span>
          <span class="peer-status">#{state}</span>
        """
        @peerList.append li

  # Get status icon based on connection state
  getStatusIcon: (status) ->
    switch status
      when "negotiating"
        '<i class="fas fa-spinner fa-spin"></i>'
      when "connecting"
        '<i class="fas fa-circle-notch fa-spin"></i>'
      when "connected"
        '<i class="fas fa-check-circle"></i>'
      when "disconnected"
        '<i class="fas fa-times-circle"></i>'
      else
        '<i class="fas fa-question-circle"></i>'
