import ApplicationController from "./application_controller"

# WebSocket P2P Controller
# Manages P2P connections using pure WebSockets via ActionCable
export default class extends ApplicationController
  @values = {
    sessionId: { type: String, default: "" },
    peerId: { type: String, default: "" },
    autoConnect: { type: Boolean, default: true },
    heartbeatInterval: { type: Number, default: 30000 }, # 30 seconds
    reconnectDelay: { type: Number, default: 2000 }, # 2 seconds
  maxReconnectAttempts: { type: Number, default: 5 },
  config: { type: Object, default: {} }
  }

  @targets = ["iframe", "status"]

  connect: ->
    console.log "[WebsocketP2pController] Connected"
    super()

    @peers = new Map()
    @messageHandlers = new Map()
    @isConnected = false
    @reconnectAttempts = 0
    @heartbeatTimer = null
    @pendingMessages = []

    # Set up iframe message handling
    @setupIframeMessaging()

    # Auto-connect if enabled
    if @autoConnectValue and @sessionIdValue and @peerIdValue
      @connectToSession()

  disconnect: ->
    console.log "[WebsocketP2pController] Disconnecting"
    @disconnectFromSession()
    super()

  # Public API methods
  connectToSession: ->
    return if @channel

    console.log "[WebsocketP2pController] Connecting to session #{@sessionIdValue} as #{@peerIdValue}"

    @updateStatus("connecting")

    # Create ActionCable subscription
    channelName = if @configValue?.useP2pStreams then "P2pStreamsChannel" else "WebsocketP2pChannel"
    @channel = App.cable.subscriptions.create(
      {
        channel: channelName,
        session_id: @sessionIdValue,
        peer_id: @peerIdValue
      },
      {
        connected: @onChannelConnected.bind(@),
        disconnected: @onChannelDisconnected.bind(@),
        received: @onChannelMessage.bind(@)
      }
    )

  disconnectFromSession: ->
    return unless @channel

    console.log "[WebsocketP2pController] Disconnecting from session"

    @updateStatus("disconnected")
    @stopHeartbeat()

    @channel.unsubscribe()
    @channel = null
    @isConnected = false
    @peers.clear()

  sendMessage: (data, toPeerId = null) ->
    message = {
      type: "message",
      data,
      to_peer_id: toPeerId
    }

    if @isConnected
      @channel.send(message)
    else
      # Queue message for when connected
      @pendingMessages.push(message)

  # Iframe communication methods
  setupIframeMessaging: ->
    return unless @hasIframeTarget

    # Listen for messages from iframe
    window.addEventListener("message", @handleIframeMessage.bind(@))

  handleIframeMessage: (event) ->
    return unless @hasIframeTarget
    return unless event.source is @iframeTarget.contentWindow

    message = event.data
    return unless message.type

    switch message.type
      when "p2p-send"
        @sendMessage(message.data)
      when "p2p-send-to"
        @sendMessage(message.data, message.peerId)
      when "iframe-ready"
        @initializeIframe()

  sendToIframe: (type, data) ->
    return unless @hasIframeTarget

    @iframeTarget.contentWindow.postMessage({
      type,
      ...data
    }, "*")

  initializeIframe: ->
    # Send initial P2P state to iframe
    @sendToIframe("p2p-init", {
      peerId: @peerIdValue,
      sessionId: @sessionIdValue,
      isHost: @isHost(),
      connected: @isConnected,
      config: @configValue
    })

    # Send current peers
    @sendPeersToIframe()

  sendPeersToIframe: ->
    participants = Array.from(@peers.values()).map (peer) =>
      {
        peerId: peer.peer_id,
        connectedAt: peer.connected_at
      }

    @sendToIframe("p2p-participants", { participants })

  # Channel event handlers
  onChannelConnected: ->
    console.log "[WebsocketP2pController] Channel connected"
    @isConnected = true
    @reconnectAttempts = 0
    @updateStatus("connected")

    # Start heartbeat
    @startHeartbeat()

    # Send queued messages
    @flushPendingMessages()

    # Notify iframe
    @sendToIframe("p2p-status", { connected: true })

  onChannelDisconnected: ->
    console.log "[WebsocketP2pController] Channel disconnected"
    @isConnected = false
    @updateStatus("disconnected")
    @stopHeartbeat()

    # Attempt reconnection
    @attemptReconnection()

    # Notify iframe
    @sendToIframe("p2p-status", { connected: false })

  onChannelMessage: (data) ->
    console.log "[WebsocketP2pController] Received:", data

    switch data.type
      when "peer_joined"
        @handlePeerJoined(data)
      when "peer_left"
        @handlePeerLeft(data)
      when "peers_list"
        @handlePeersList(data)
      when "message"
        @handleP2pMessage(data)
      when "heartbeat_ack"
        # Heartbeat acknowledged
        console.log "[WebsocketP2pController] Heartbeat ack received"

  handlePeerJoined: (data) ->
    return if data.peer_id is @peerIdValue # Ignore self

    console.log "[WebsocketP2pController] Peer joined:", data.peer_id

    @peers.set(data.peer_id, {
      peer_id: data.peer_id,
      connected_at: data.timestamp
    })

    @sendPeersToIframe()

  handlePeerLeft: (data) ->
    return if data.peer_id is @peerIdValue # Ignore self

    console.log "[WebsocketP2pController] Peer left:", data.peer_id

    @peers.delete(data.peer_id)
    @sendPeersToIframe()

  handlePeersList: (data) ->
    console.log "[WebsocketP2pController] Received peers list:", data.peers

    @peers.clear()
    data.peers.forEach (peer) =>
      return if peer.peer_id is @peerIdValue # Ignore self
      @peers.set(peer.peer_id, peer)

    @sendPeersToIframe()

  handleP2pMessage: (data) ->
    console.log "[WebsocketP2pController] P2P message from #{data.from_peer_id}:", data.data

    # Forward to iframe
    @sendToIframe("p2p-message", {
      senderId: data.from_peer_id,
      data,
      timestamp: data.timestamp
    })

  # Utility methods
  updateStatus: (status) ->
    console.log "[WebsocketP2pController] Status: #{status}"

    if @hasStatusTarget
      @statusTarget.textContent = status
      @statusTarget.className = "p2p-status p2p-status-#{status}"

  isHost: ->
    # First peer in session is considered host (simple logic)
    Array.from(@peers.keys()).length is 0

  startHeartbeat: ->
    return if @heartbeatTimer

    @heartbeatTimer = setInterval =>
      if @isConnected
        @channel.send({ type: "heartbeat" })
    , @heartbeatIntervalValue

  stopHeartbeat: ->
    if @heartbeatTimer
      clearInterval(@heartbeatTimer)
      @heartbeatTimer = null

  flushPendingMessages: ->
    while @pendingMessages.length > 0
      message = @pendingMessages.shift()
      @channel.send(message)

  attemptReconnection: ->
    return if @reconnectAttempts >= @maxReconnectAttemptsValue

    @reconnectAttempts += 1

    console.log "[WebsocketP2pController] Reconnection attempt #{@reconnectAttempts}/#{@maxReconnectAttemptsValue}"

    setTimeout =>
      @connectToSession() unless @isConnected
    , @reconnectDelayValue

  # Value change handlers
  sessionIdValueChanged: ->
    if @channel
      @disconnectFromSession()
      @connectToSession() if @sessionIdValue

  peerIdValueChanged: ->
    if @channel
      @disconnectFromSession()
      @connectToSession() if @peerIdValue
