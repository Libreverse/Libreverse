import ApplicationController from "./application_controller"
import * as Y from "yjs"

# Yjs Collaboration Controller (WebSocket-only)
# Attaches to the same element as websocket-p2p or a nested element.
export default class extends ApplicationController
  @values = {
    sessionId: String,
    autoBootstrap: { type: Boolean, default: true }
  }


  connect: ->
    super()
    @ydoc = new Y.Doc()
    @pending = []
    @flushTimer = null
    @finalized = false
    @relaxedSync = false

    @channel = App.cable.subscriptions.create({
      channel: "WebsocketP2pChannel",
      session_id: @sessionIdValue,
      peer_id: "yjs_#{Math.random().toString(36).slice(2, 10)}"
    }, {
      received: @received.bind(@),
      connected: =>
        if @autoBootstrapValue
          @channel.send({ type: "yjs_bootstrap_request" })
    })

    @ydoc.on "update", (update, origin) =>
      return if @finalized
      return if origin is 'remote'
      if @relaxedSync
        # Only store update, don't send immediately
        @pending.push(update)
      else
        b64 = btoa(Array.from(update, (byte) => String.fromCharCode(byte)).join(''))
        @pending.push(b64)
        @scheduleFlush()

    # Listen for sync mode changes
    window.addEventListener "sync-mode-changed", (e) =>
      @relaxedSync = e.detail.mode is "relaxed"
      if not @relaxedSync
        # If switching to strict, immediately flush all pending updates
        @flushAllPending()

    # Listen for visibility changes
    document.addEventListener "visibilitychange", =>
      if @relaxedSync
        if document.visibilityState is "hidden"
          @flushAllPending()

  flushAllPending: =>
    if @pending.length > 0
      # Merge all pending updates into one update
      merged = null
      try
        merged = Y.mergeUpdates(@pending)
      catch error
        # fallback: send individually
        merged = null
      if merged
        b64 = btoa(Array.from(merged, (byte) => String.fromCharCode(byte)).join(''))
        @channel.send({ type: 'yjs_update', update_b64: b64 })
      else
        for update in @pending
          b64 = btoa(Array.from(update, (byte) => String.fromCharCode(byte)).join(''))
          @channel.send({ type: 'yjs_update', update_b64: b64 })
      @pending = []

  disconnect: =>
    # Unsubscribe from ActionCable channel to stop receiving messages
    if @channel?.unsubscribe?
      @channel.unsubscribe()

    # Clear any scheduled flush
    if @flushTimer?
      clearTimeout(@flushTimer)
      @flushTimer = null
    @ydoc?.destroy()
    super()

  received: (msg) =>
    switch msg.type
      when 'yjs_bootstrap'
        if msg.base_b64?.length > 0
          Y.applyUpdate(@ydoc, @decode(msg.base_b64), 'remote')
        for u in msg.updates
          Y.applyUpdate(@ydoc, @decode(u), 'remote')
      when 'yjs_update'
        return if msg.from_peer_id is @channel.identifier.peer_id
        Y.applyUpdate(@ydoc, @decode(msg.update_b64), 'remote')
      when 'session_finalized'
        @finalized = true

  scheduleFlush: =>
    return if @flushTimer
    @flushTimer = setTimeout(=>
      batch = @pending
      @pending = []
      clearTimeout(@flushTimer)
      @flushTimer = null
      for u in batch
        @channel.send({ type: 'yjs_update', update_b64: u })
    , 25)

  decode: (b64) =>
    str = atob(b64)
    Uint8Array.from(str, (c) => c.charCodeAt(0))
