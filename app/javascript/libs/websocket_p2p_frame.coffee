# WebSocket P2P Frame Custom Element
# Provides backwards compatible p2p-frame element with WebSocket implementation

class WebSocketP2PFrame extends HTMLElement
  constructor: ->
    super()
    @connected = false
    @observer = null

  connectedCallback: ->
    console.log "[WebSocketP2PFrame] Connected"

    # Get configuration from attributes
    @sessionId = @getAttribute("session-id") or @getAttribute("session_id")
    @peerId = @getAttribute("peer-id") or @getAttribute("peer_id")
    @config = @parseConfig()

    # Set up the controller
    @setupController()

    # Watch for iframe changes
    @watchForIframe()

  disconnectedCallback: ->
    console.log "[WebSocketP2PFrame] Disconnected"

    if @observer
      @observer.disconnect()

  setupController: ->
    # Add WebSocket P2P controller
    @setAttribute("data-controller", "websocket-p2p")
    @setAttribute("data-websocket-p2p-session-id-value", @sessionId)
    @setAttribute("data-websocket-p2p-peer-id-value", @peerId)
    try
      @setAttribute("data-websocket-p2p-config-value", JSON.stringify(@config))
    catch error
      console.warn "[WebSocketP2PFrame] Failed to serialize config:", error

    # Set up iframe target
    iframe = @querySelector("iframe")
    if iframe
      iframe.setAttribute("data-websocket-p2p-target", "iframe")

  watchForIframe: ->
    # Watch for iframe being added/changed
    @observer = new MutationObserver((mutations) =>
      mutations.forEach (mutation) =>
        mutation.addedNodes.forEach (node) =>
          if node.tagName is "IFRAME"
            node.setAttribute("data-websocket-p2p-target", "iframe")
    )
    @observer.observe(@, { childList: true, subtree: true })

  parseConfig: ->
    configAttr = @getAttribute("config")
    return {} unless configAttr

    try
      JSON.parse(configAttr)
    catch error
      console.warn "[WebSocketP2PFrame] Invalid config JSON:", error
      {}

  # Static method to register the custom element
  @register: ->
    unless customElements.get("p2p-frame")
      customElements.define("p2p-frame", WebSocketP2PFrame)

# Auto-register when loaded
WebSocketP2PFrame.register()

export default WebSocketP2PFrame
