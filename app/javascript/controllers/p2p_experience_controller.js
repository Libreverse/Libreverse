import { P2pController } from "p2p"

export default class extends P2pController {
    static targets = ["iframe", "status", "participantsList"]
    static values = { 
        experienceId: String,
        sessionId: String 
    }

    connect() {
        super.connect()
        this.setupIframeMessaging()
        this.updateStatus("Connecting to peers...")
    }

    // P2P event handlers
    p2pNegotiating() {
        this.updateStatus("Negotiating connection...")
    }

    p2pConnecting() {
        this.updateStatus("Connecting to peers...")
    }

    p2pConnected() {
        this.updateStatus(`Connected! You are ${this.iamHost ? 'hosting' : 'participating in'} this session.`)
        this.broadcastToIframe({
            type: "p2p-status",
            connected: true,
            isHost: this.iamHost,
            peerId: this.peerId,
            hostPeerId: this.hostPeerId
        })
    }

    p2pDisconnected() {
        this.updateStatus("Disconnected from peers")
        this.broadcastToIframe({
            type: "p2p-status", 
            connected: false
        })
    }

    p2pClosed() {
        this.updateStatus("Session ended")
    }

    p2pError() {
        this.updateStatus("Connection error occurred")
    }

    // Handle messages from P2P network
    p2pReceivedMessage(message) {
        switch(message.type) {
            case "Data": {
                // Forward data messages to the iframe
                this.broadcastToIframe({
                    type: "p2p-message",
                    senderId: message.senderId,
                    data: message.data
                })
                break
            }
            case "Data.Connection.State": {
                // Update participants list
                this.updateParticipants(message.data)
                this.broadcastToIframe({
                    type: "p2p-participants",
                    participants: message.data
                })
                break
            }
        }
    }

    // Setup communication with the iframe
    setupIframeMessaging() {
        globalThis.addEventListener("message", (event) => {
            // Verify origin is from our iframe
            if (event.source !== this.iframeTarget.contentWindow) return

            const { type, data } = event.data

            switch(type) {
                case "p2p-send": {
                    // Forward message from iframe to P2P network
                    this.p2pSendMessage(data)
                    break
                }
                case "iframe-ready": {
                    // Iframe is loaded and ready for P2P
                    this.onIframeReady()
                    break
                }
            }
        })
    }

    // Send message to iframe
    broadcastToIframe(message) {
        if (this.iframeTarget && this.iframeTarget.contentWindow) {
            this.iframeTarget.contentWindow.postMessage(message, "*")
        }
    }

    // Called when iframe signals it's ready
    onIframeReady() {
        // Send initial P2P state to iframe
        this.broadcastToIframe({
            type: "p2p-init",
            sessionId: this.sessionIdValue,
            experienceId: this.experienceIdValue,
            peerId: this.peerId,
            isHost: this.iamHost
        })
    }

    // Update status display
    updateStatus(message) {
        if (this.hasStatusTarget) {
            this.statusTarget.textContent = message
        }
    }

    // Update participants list
    updateParticipants(participantStates) {
        if (!this.hasParticipantsListTarget) return

        const participants = Object.entries(participantStates).map(([peerId, state]) => ({
            id: peerId,
            state: state,
            isHost: peerId === this.hostPeerId,
            isMe: peerId === this.peerId
        }))

        this.participantsListTarget.innerHTML = participants.map(p => 
            `<li class="participant ${p.isHost ? 'host' : ''} ${p.isMe ? 'me' : ''}">
                ${p.isHost ? '👑 ' : ''}${p.isMe ? 'You' : `Peer ${p.id.slice(-6)}`}
                <span class="status">${p.state}</span>
             </li>`
        ).join('')
    }

    // Actions for user controls
    startSession(event) {
        event.preventDefault()
        // Session starts automatically when P2P connects
        this.updateStatus("Starting session...")
    }

    leaveSession(event) {
        event.preventDefault()
        globalThis.location.href = `/experiences/${this.experienceIdValue}`
    }
}
