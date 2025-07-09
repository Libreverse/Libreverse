// WebSocket P2P Client Library for Libreverse Experiences
// Provides backwards compatible API with the previous P2P implementation

class LibreverseWebSocketP2P {
    constructor() {
        this.connected = false;
        this.isHost = false;
        this.peerId = null;
        this.sessionId = null;
        this.participants = {};
        this.messageHandlers = new Map();
        this.status = "disconnected";

        // Listen for messages from parent window (Libreverse app)
        window.addEventListener("message", (event) => {
            this.handleParentMessage(event.data);
        });

        // Signal that iframe is ready
        this.sendToParent("iframe-ready", {});
    }

    // Send message to parent window (Libreverse app)
    sendToParent(type, data) {
        window.parent.postMessage({ type, data }, "*");
    }

    // Handle messages from parent window
    handleParentMessage(message) {
        if (!message || !message.type) return;

        switch (message.type) {
            case "p2p-init":
                this.peerId = message.peerId;
                this.sessionId = message.sessionId;
                this.isHost = message.isHost;
                this.connected = message.connected;
                this.onInit(message);
                break;

            case "p2p-status":
                this.connected = message.connected;
                this.status = message.connected ? "connected" : "disconnected";
                this.onStatusChange(message);
                break;

            case "p2p-message":
                this.onMessage(message.senderId, message.data);
                break;

            case "p2p-participants":
                this.participants = {};
                message.participants.forEach((participant) => {
                    this.participants[participant.peerId] = participant;
                });
                this.onParticipantsChange(this.participants);
                break;
        }
    }

    // Send P2P message to all peers
    send(data) {
        if (!this.connected) {
            console.warn("WebSocket P2P not connected");
            return false;
        }

        this.sendToParent("p2p-send", data);
        return true;
    }

    // Send P2P message to specific peer
    sendTo(peerId, data) {
        if (!this.connected) {
            console.warn("WebSocket P2P not connected");
            return false;
        }

        this.sendToParent("p2p-send-to", { peerId, data });
        return true;
    }

    // Get list of connected peers
    getPeers() {
        return Object.keys(this.participants);
    }

    // Get participant info
    getParticipant(peerId) {
        return this.participants[peerId];
    }

    // Check if connected to session
    isConnected() {
        return this.connected;
    }

    // Get connection status
    getStatus() {
        return this.status;
    }

    // Event handlers (can be overridden by experience)
    onInit(data) {
        console.log("WebSocket P2P initialized:", data);
    }

    onStatusChange(status) {
        console.log("WebSocket P2P status changed:", status);
    }

    onMessage(senderId, data) {
        console.log("WebSocket P2P message from", senderId, ":", data);

        // Call registered message handlers
        this.messageHandlers.forEach((handler) => {
            try {
                handler(senderId, data);
            } catch (error) {
                console.error("Error in P2P message handler:", error);
            }
        });
    }

    onParticipantsChange(participants) {
        console.log("WebSocket P2P participants changed:", participants);
    }

    // Register message handler
    addMessageHandler(handler) {
        if (typeof handler !== "function") {
            throw new Error("Message handler must be a function");
        }

        const id = Symbol();
        this.messageHandlers.set(id, handler);

        // Return unsubscribe function
        return () => this.messageHandlers.delete(id);
    }

    // Remove all message handlers
    clearMessageHandlers() {
        this.messageHandlers.clear();
    }

    // Backwards compatibility: support old callback style
    set onMessage(callback) {
        if (typeof callback === "function") {
            this.clearMessageHandlers();
            this.addMessageHandler(callback);
        }
    }
}

// Create global instance for backward compatibility
if (typeof window !== "undefined") {
    // Make P2P available globally in the experience
    window.LibreverseP2P = new LibreverseWebSocketP2P();

    // Convenient shorthand
    window.P2P = window.LibreverseP2P;

    // Also expose the class for advanced usage
    window.LibreverseWebSocketP2P = LibreverseWebSocketP2P;
}

// Export for module usage
if (typeof module !== "undefined" && module.exports) {
    module.exports = LibreverseWebSocketP2P;
}

export default LibreverseWebSocketP2P;
