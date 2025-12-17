import { Controller } from "@hotwired/stimulus";
import consumer from "../channels/consumer";
import {
    V1_INBOUND_TYPES,
    V1_OUTBOUND_TYPES,
    buildV1OutboundMessage,
    normalizeV1InboundMessage,
} from "../lib/multiplayer/iframe_api/v1";

export default class extends Controller {
    static values = {
        sessionId: String,
        peerId: String,
    };

    static targets = ["iframe"];

    connect() {
        console.log("[ExperienceState] Connecting...", this.sessionIdValue);

        this.state = {};

        // Keep a stable reference so removeEventListener works.
        this._boundHandleMessage = this._handleMessage.bind(this);

        this.subscription = consumer.subscriptions.create(
            {
                channel: "ExperienceChannel",
                session_id: this.sessionIdValue,
                peer_id: this.peerIdValue,
            },
            {
                connected: this._onConnected.bind(this),
                disconnected: this._onDisconnected.bind(this),
                received: this._onReceived.bind(this),
            },
        );

        window.addEventListener("message", this._boundHandleMessage);
    }

    disconnect() {
        if (this.subscription) {
            this.subscription.unsubscribe();
        }

        if (this._boundHandleMessage) {
            window.removeEventListener("message", this._boundHandleMessage);
            this._boundHandleMessage = null;
        }
    }

    // API for the iframe
    _handleMessage(event) {
        // Security check: ensure message comes from the iframe
        if (
            this.hasIframeTarget &&
            event.source !== this.iframeTarget.contentWindow
        )
            return;

        const msg = normalizeV1InboundMessage(event.data);
        if (!msg) return;

        const { type, key, value } = msg;

        if (type === V1_INBOUND_TYPES.STATE_SET) {
            this.updateState(key, value);
        } else if (type === V1_INBOUND_TYPES.STATE_GET) {
            // Reply with current value
            this._sendToIframe(V1_OUTBOUND_TYPES.STATE_VALUE, {
                key,
                value: this.state[key],
            });
        } else if (type === V1_INBOUND_TYPES.STATE_REQUEST_ALL) {
            this._sendToIframe(V1_OUTBOUND_TYPES.STATE_SNAPSHOT, {
                state: this.state,
            });
        }
    }

    updateState(key, value) {
        // Optimistic update
        this.state[key] = value;

        // Send to server
        this.subscription.send({
            type: "update",
            api_version: 1,
            key,
            value,
        });
    }

    _onConnected() {
        console.log("[ExperienceState] Connected");
        this._sendToIframe(V1_OUTBOUND_TYPES.CONNECTED, {
            peerId: this.peerIdValue,
        });
    }

    _onDisconnected() {
        console.log("[ExperienceState] Disconnected");
        this._sendToIframe(V1_OUTBOUND_TYPES.DISCONNECTED, {});
    }

    _onReceived(data) {
        switch (data.type) {
            case "state_snapshot":
                this.state = data.state || {};
                this._sendToIframe(V1_OUTBOUND_TYPES.STATE_SNAPSHOT, {
                    state: this.state,
                });
                break;
            case "state_update":
                // Don't echo back our own updates if we already applied them optimistically
                // But here we just apply everything to be safe/consistent
                if (data.from_peer_id !== this.peerIdValue) {
                    this.state[data.key] = data.value;
                    this._sendToIframe(V1_OUTBOUND_TYPES.STATE_UPDATE, {
                        key: data.key,
                        value: data.value,
                        fromPeerId: data.from_peer_id,
                    });
                }
                break;
        }
    }

    _sendToIframe(type, payload) {
        if (this.hasIframeTarget && this.iframeTarget.contentWindow) {
            this.iframeTarget.contentWindow.postMessage(
                buildV1OutboundMessage(type, payload),
                "*",
            );
        }
    }
}
