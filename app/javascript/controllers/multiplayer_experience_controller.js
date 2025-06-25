import { P2pController } from "p2p"

export default class extends P2pController {
    static values = { 
        sessionId: String, 
        peerId: String 
    }

    connect() {
        super.connect() // Call parent P2pController connect
        
        this.iframe = document.querySelector('#experience-iframe')
        this.statusIndicator = document.querySelector('#status-indicator')
        this.peerList = document.querySelector('#peer-list')
        
        // Bind the message handler for removal later
        this.boundHandleIframeMessage = this.handleIframeMessage.bind(this)
        
        // Listen for messages from the iframe
        window.addEventListener('message', this.boundHandleIframeMessage)
        
        // Wait for iframe to load then initialize
        if (this.iframe.contentDocument?.readyState === 'complete') {
            this.initializeIframe()
        } else {
            this.iframe.addEventListener('load', () => this.initializeIframe())
        }
    }

    disconnect() {
        window.removeEventListener('message', this.boundHandleIframeMessage)
    }

    // P2P Connection Event Handlers
    p2pNegotiating() {
        console.log("P2P Negotiating...")
        this.updateStatus('negotiating', 'Connecting to peers...')
    }

    p2pConnecting() {
        console.log("P2P Connecting...")
        this.updateStatus('connecting', 'Establishing connection...')
    }

    p2pConnected() {
        console.log("P2P Connected!")
        this.updateStatus('connected', 'Connected to multiplayer session')
        
        // Notify iframe that P2P is connected
        this.sendToIframe('p2p-status', { 
            connected: true, 
            isHost: this.iamHost,
            peerId: this.peerId
        })
    }

    p2pDisconnected() {
        console.log("P2P Disconnected")
        this.updateStatus('disconnected', 'Disconnected from peers')
        
        // Notify iframe about disconnection
        this.sendToIframe('p2p-status', { 
            connected: false,
            peerId: this.peerId
        })
    }

    p2pClosed() {
        console.log("P2P Closed")
        this.updateStatus('disconnected', 'Connection closed')
    }

    p2pError() {
        console.log("P2P Error")
        this.updateStatus('disconnected', 'Connection error')
    }

    // Handle messages from other peers
    p2pReceivedMessage(message) {
        switch(message.type) {
            case "Data": {
                // Forward peer messages to iframe
                this.sendToIframe('p2p-message', {
                    senderId: message.senderId,
                    data: message.data
                })
                break
            }
                
            case "Data.Connection.State": {
                // Update peer list and notify iframe
                this.updatePeerList(message.data)
                this.sendToIframe('p2p-participants', {
                    participants: message.data
                })
                break
            }
                
            default: {
                console.log('Unknown P2P message type:', message.type)
                break
            }
        }
    }

    // Handle messages from the iframe experience
    handleIframeMessage(event) {
        // Only accept messages from our iframe
        if (event.source !== this.iframe.contentWindow) return
        
        const { type, data } = event.data
        
        switch(type) {
            case 'iframe-ready': {
                console.log('Iframe ready for P2P')
                this.initializeIframe()
                break
            }
                
            case 'p2p-send': {
                // Forward message from iframe to other peers
                if (this.p2pFrame && this.p2pFrame.peer) {
                    this.p2pSendMessage(data)
                }
                break
            }
                
            default: {
                console.log('Unknown iframe message type:', type)
                break
            }
        }
    }

    // Send message to iframe
    sendToIframe(type, data) {
        if (this.iframe && this.iframe.contentWindow) {
            this.iframe.contentWindow.postMessage({ type, data }, '*')
        }
    }

    // Initialize P2P connection in iframe
    initializeIframe() {
        this.sendToIframe('p2p-init', {
            peerId: this.peerIdValue,
            sessionId: this.sessionIdValue,
            isHost: this.iamHost || false,
            connected: false
        })
    }

    // Update connection status display
    updateStatus(status, message) {
        if (this.statusIndicator) {
            // Remove all status classes
            this.statusIndicator.className = 'status-indicator'
            // Add current status class
            this.statusIndicator.classList.add(status)
            
            // Update status text
            const icon = this.getStatusIcon(status)
            this.statusIndicator.innerHTML = `${icon} ${message}`
        }
    }

    // Update the list of connected peers
    updatePeerList(participants) {
        if (!this.peerList) return
        
        // Clear current list except for self
        const selfItem = this.peerList.querySelector('li')
        this.peerList.innerHTML = ''
        if (selfItem) {
            this.peerList.append(selfItem)
        }
        
        // Add other peers
        for (const [peerId, state] of Object.entries(participants)) {
            if (peerId !== this.peerIdValue) {
                const li = document.createElement('li')
                li.innerHTML = `
                    <span class="peer-id">${peerId}</span>
                    <span class="peer-status">${state}</span>
                `
                this.peerList.append(li)
            }
        }
    }

    // Get status icon based on connection state
    getStatusIcon(status) {
        switch(status) {
            case 'negotiating': {
                return '<i class="fas fa-spinner fa-spin"></i>'
            }
            case 'connecting': {
                return '<i class="fas fa-circle-notch fa-spin"></i>'
            }
            case 'connected': {
                return '<i class="fas fa-check-circle"></i>'
            }
            case 'disconnected': {
                return '<i class="fas fa-times-circle"></i>'
            }
            default: {
                return '<i class="fas fa-question-circle"></i>'
            }
        }
    }
}
