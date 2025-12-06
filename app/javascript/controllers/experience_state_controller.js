import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

export default class extends Controller {
  static values = {
    sessionId: String,
    peerId: String
  }

  static targets = ["iframe"]

  connect() {
    console.log("[ExperienceState] Connecting...", this.sessionIdValue)
    
    this.state = {}
    this.subscription = consumer.subscriptions.create(
      {
        channel: "ExperienceChannel",
        session_id: this.sessionIdValue,
        peer_id: this.peerIdValue
      },
      {
        connected: this._onConnected.bind(this),
        disconnected: this._onDisconnected.bind(this),
        received: this._onReceived.bind(this)
      }
    )

    window.addEventListener("message", this._handleMessage.bind(this))
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
    window.removeEventListener("message", this._handleMessage.bind(this))
  }

  // API for the iframe
  _handleMessage(event) {
    // Security check: ensure message comes from the iframe
    if (this.hasIframeTarget && event.source !== this.iframeTarget.contentWindow) return
    
    const { type, key, value } = event.data
    
    if (type === "state_set") {
      this.updateState(key, value)
    } else if (type === "state_get") {
      // Reply with current value
      this._sendToIframe("state_value", { key, value: this.state[key] })
    } else if (type === "state_request_all") {
      this._sendToIframe("state_snapshot", { state: this.state })
    }
  }

  updateState(key, value) {
    // Optimistic update
    this.state[key] = value
    
    // Send to server
    this.subscription.send({
      type: "update",
      key,
      value
    })
  }

  _onConnected() {
    console.log("[ExperienceState] Connected")
    this._sendToIframe("connected", { peerId: this.peerIdValue })
  }

  _onDisconnected() {
    console.log("[ExperienceState] Disconnected")
    this._sendToIframe("disconnected", {})
  }

  _onReceived(data) {
    switch (data.type) {
      case "state_snapshot":
        this.state = data.state || {}
        this._sendToIframe("state_snapshot", { state: this.state })
        break
      case "state_update":
        // Don't echo back our own updates if we already applied them optimistically
        // But here we just apply everything to be safe/consistent
        if (data.from_peer_id !== this.peerIdValue) {
            this.state[data.key] = data.value
            this._sendToIframe("state_update", { key: data.key, value: data.value, fromPeerId: data.from_peer_id })
        }
        break
    }
  }

  _sendToIframe(type, payload) {
    if (this.hasIframeTarget && this.iframeTarget.contentWindow) {
      this.iframeTarget.contentWindow.postMessage({ type, ...payload }, "*")
    }
  }
}
