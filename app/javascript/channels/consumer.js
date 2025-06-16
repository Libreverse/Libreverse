// Action Cable provides the framework to deal with WebSockets in Rails.
// You can generate new channels where WebSocket features live using the `bin/rails generate channel` command.

import { createConsumer } from "@rails/actioncable";

// Create the consumer
const consumer = createConsumer();

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
