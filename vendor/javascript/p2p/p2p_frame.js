// @ts-nocheck
import { Turbo, cable } from "@hotwired/turbo-rails"
import P2pPeer from "p2p/p2p_peer"
import { MessageType } from "p2p/message"

class P2pFrameElement extends HTMLElement {
  constructor() {
    super()
    this.listeners ||= []
    this.isUnsubscribing = false
    this.subscription = null
    this.peer = null
  }

  // called each time the element is added to the document.
  async connectedCallback() {
    Turbo.connectStreamSource(this)
    try {
      this.subscription = await cable.subscribeTo(this.channel, {
        received: this.receiveSignal.bind(this),
        connected: this.subscriptionConnected.bind(this),
        disconnected: this.subscriptionDisconnected.bind(this)
      })
    } catch (err) {
      console.error('Failed to subscribe to channel:', err)
    }

    if (!this.subscription) {
      console.error('Cannot create peer without subscription')
      return
    }

    this.peer = new P2pPeer(
      this.sessionId,
      this.peerId,
      this,
      this.subscription,
      this.iceConfig,
      this.heartbeatConfig
    )
  }

  // called each time the element is removed from the document.
  disconnectedCallback() {
    if (this.peer) {
      this.peer.cleanup?.()
      this.peer = null
    }
    this.unsubscribeSignalChannel()
  }

  subscriptionConnected() {
    this.peer?.setup?.()
  }

  subscriptionDisconnected() {
    // no-op
  }

  receiveSignal(message) {
    if (message?.type === MessageType.Connection) {
      this.peer?.negotiate?.(message)
    }
  }

  setP2pListener(listener) {
    this.listeners ||= []
    this.listeners.push(listener)
  }

  dispatchP2pMessage(message) {
    this.listeners.forEach(listener => {
      listener.p2pReceivedMessage?.(message)
    })
  }

  sendP2pMessage(msg) {
    this.peer?.sendP2pMessage?.(msg)
  }

  // Negotiation phase maps to standard "connecting" state now
  p2pConnecting() {
    this.listeners.forEach(listener => {
      listener.p2pConnecting?.()
    })
  }

  p2pConnected() {
    this.listeners.forEach(listener => {
      listener.p2pConnected?.()
    })

    // only host-peer retain connect to the signal server
    if (!this.peer?.iamHost && !this.keepCableConnection) {
      this.unsubscribeSignalChannel()
    }
  }

  p2pDisconnected() {
    this.listeners.forEach(listener => {
      listener.p2pDisconnected?.()
    })
  }

  p2pError() {
    this.listeners.forEach(listener => {
      listener.p2pError?.()
    })
  }

  async unsubscribeSignalChannel() { // TODO: MAKE SURE `SignalingChannel stopped streaming`
    if (this.isUnsubscribing) return
    this.isUnsubscribing = true

    try {
      if (this.subscription) {
        this.subscription.unsubscribe()
        this.subscription = null
      }
      Turbo.disconnectStreamSource(this)
      const consumer = await cable.getConsumer()
      if (consumer) consumer.disconnect()
    } catch (e) {
      console.error('Failed to unsubscribe signal channel:', e)
    } finally {
      this.isUnsubscribing = false
    }
  }

  get params() {
    try {
      return JSON.parse(this.getAttribute("params") || "{}")
    } catch (e) {
      console.warn("Invalid JSON in params attribute:", e)
      return {}
    }
  }

  get config() {
    return this.params["config"] || {}
  }

  get peerId() {
    return this.getAttribute("peer-id")
  }

  get sessionId() {
    return this.getAttribute("session-id")
  }

  get iceConfig() {
    return {
      iceServers: this.config["ice_servers"] || []
    }
  }

  get heartbeatConfig() {
    return this.config["heartbeat"]
  }

  get keepCableConnection() {
    return !!this.config["keep_cable_connection"]
  }

  get channel() {
    const channel = this.getAttribute("channel")
    const signed_stream_name = this.getAttribute("signed-stream-name")
    return {
      channel: channel,
      signed_stream_name: signed_stream_name,
      session_id: this.sessionId,
      peer_id: this.peerId
    }
  }
}

customElements.define("p2p-frame", P2pFrameElement)
