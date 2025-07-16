// WebSocket P2P Client Library for Libreverse Experiences
// Provides backwards compatible API with the previous P2P implementation

class LibreverseWebSocketP2P {
    constructor() {
        this.connected = false;
        this.isHost = false;
        this.peerId = undefined;
        this.sessionId = undefined;
        this.participants = {};
        this.messageHandlers = new Map();
        this.status = "disconnected";

        // Listen for messages from parent window (Libreverse app)
        window.addEventListener("message", (event) => {
            // Origin check for security - only accept messages from same origin
            if (event.origin !== globalThis.location.origin) {
                console.warn(
                    "WebSocket P2P: Ignored message from untrusted origin:",
                    event.origin,
                );
                return;
            }

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
            case "p2p-init": {
                this.peerId = message.peerId;
                this.sessionId = message.sessionId;
                this.isHost = message.isHost;
                this.connected = message.connected;
                this.onInit(message);
                break;
            }

            case "p2p-status": {
                this.connected = message.connected;
                this.status = message.connected ? "connected" : "disconnected";
                this.onStatusChange(message);
                break;
            }

            case "p2p-message": {
                this.onMessage(message.senderId, message.data);
                break;
            }

            case "p2p-participants": {
                this.participants = {};
                for (const participant of message.participants) {
                    // Validate participant data and sanitize peerId
                    if (
                        participant &&
                        typeof participant.peerId === "string" &&
                        participant.peerId.length > 0
                    ) {
                        // Only allow alphanumeric characters and hyphens for peer IDs
                        const sanitizedPeerId = participant.peerId.replaceAll(
                            /[^a-zA-Z0-9-]/g,
                            "",
                        );
                        if (sanitizedPeerId.length > 0) {
                            this.participants[sanitizedPeerId] = {
                                peerId: sanitizedPeerId,
                                // Copy other safe properties with validation
                                ...Object.fromEntries(
                                    Object.entries(participant).filter(
                                        ([key, value]) =>
                                            key !== "peerId" &&
                                            typeof value === "string",
                                    ),
                                ),
                            };
                        }
                    }
                }
                this.onParticipantsChange(this.participants);
                break;
            }
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
        for (const handler of this.messageHandlers) {
            try {
                handler(senderId, data);
            } catch (error) {
                console.error("Error in P2P message handler:", error);
            }
        }
    }

    onParticipantsChange(participants) {
        console.log("WebSocket P2P participants changed:", participants);
    }

    // Register message handler
    addMessageHandler(handler) {
        if (typeof handler !== "function") {
            throw new TypeError("Message handler must be a function");
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
    set onMessageCallback(callback) {
        if (typeof callback === "function") {
            this.clearMessageHandlers();
            this.addMessageHandler(callback);
        }
    }
}

// Create global instance for backward compatibility
if (typeof globalThis !== "undefined") {
    // Make P2P available globally in the experience
    globalThis.LibreverseP2P = new LibreverseWebSocketP2P();

    // Convenient shorthand
    globalThis.P2P = globalThis.LibreverseP2P;

    // Also expose the class for advanced usage
    globalThis.LibreverseWebSocketP2P = LibreverseWebSocketP2P;
}

export default LibreverseWebSocketP2P;
