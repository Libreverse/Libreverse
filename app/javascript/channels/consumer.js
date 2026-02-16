// Action Cable provides the framework to deal with WebSockets in Rails.
// You can generate new channels where WebSocket features live using the `bin/rails generate channel` command.

import { createConsumer } from "@anycable/core";
import { start } from "@anycable/turbo-stream";

// Create consumer using the Action Cable URL from meta tag
const actionCableUrl = document
    .querySelector('meta[name="action-cable-url"]')
    ?.getAttribute("content");

// Enhanced configuration for AnyCable with JWT support and optimizations
const consumer = createConsumer(actionCableUrl, {
    // Enable AnyCable's extended protocol features
    protocolVersion: "actioncable-v1-ext-json",

    // JWT token support - will be automatically extracted from cookies or headers
    token: () => {
        // Try to get JWT from cookie first
        const jwtCookie = document.cookie
            .split("; ")
            .find((row) => row.startsWith("anycable_jwt="))
            ?.split("=")[1];

        if (jwtCookie) return jwtCookie;

        // Fallback to meta tag or localStorage
        return (
            document
                .querySelector('meta[name="anycable-jwt"]')
                ?.getAttribute("content") ||
            localStorage.getItem("anycable_jwt")
        );
    },

    // Enable session restoration for faster reconnections
    sessionId: () => sessionStorage.getItem("anycable_session_id") || undefined,

    // Store session ID for restoration
    onSessionId: (sessionId) => {
        if (sessionId) {
            sessionStorage.setItem("anycable_session_id", sessionId);
        }
    },

    // Enable reliable streams with history recovery
    historyEnabled: true,
    historySize: 50, // Keep last 50 messages for recovery

    // Connection optimization settings
    connectionTimeout: 15_000,
    reconnectInterval: 1000,
    maxReconnectAttempts: 10,
});

// Initialize Turbo Stream support
start(consumer);

// Log all ActionCable messages in development
if (import.meta.env.MODE === "development") {
    // Store the original create method
    const originalCreate = consumer.subscriptions.create.bind(
        consumer.subscriptions,
    );

    consumer.subscriptions.create = function (...channelSubscriptionArguments) {
        const [channelName, config = {}] = channelSubscriptionArguments;
        const originalReceived = config.received;

        config.received = function (data) {
            console.log("ActionCable Received:", channelName, data);
            if (originalReceived) originalReceived.call(this, data);
        };

        channelSubscriptionArguments[1] = config; // replace in the arg list
        const subscription = originalCreate(...channelSubscriptionArguments);
        console.log("ActionCable Subscription Created:", channelName);
        return subscription;
    };

    const originalSend = consumer.send.bind(consumer);
    consumer.send = function (data) {
        console.log("ActionCable Sent:", data);
        return originalSend(data);
    };
}

export default consumer;
