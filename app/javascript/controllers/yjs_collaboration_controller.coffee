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

    @channel = App.cable.subscriptions.create({
      channel: "WebsocketP2pChannel",
      session_id: @sessionIdValue,
      peer_id: "yjs_#{Math.random().toString(36).slice(2,10)}"
    }, {
      received: @received.bind(@),
      connected: =>
        if @autoBootstrapValue
          @channel.send({ type: "yjs_bootstrap_request" })
    })

    @ydoc.on "update", (update, origin) =>
      return if @finalized
      return if origin is 'remote'
      b64 = btoa(String.fromCharCode.apply(null, update))
      @pending.push(b64)
      @scheduleFlush()

  disconnect: ->
    @ydoc?.destroy()
    super()

  received: (msg) ->
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

  scheduleFlush: ->
    return if @flushTimer
    @flushTimer = setTimeout(() =>
      batch = @pending
      @pending = []
      clearTimeout(@flushTimer)
      @flushTimer = null
      for u in batch
        @channel.send({ type: 'yjs_update', update_b64: u })
    , 25)

  decode: (b64) ->
    str = atob(b64)
    Uint8Array.from(str, (c) -> c.charCodeAt(0))
