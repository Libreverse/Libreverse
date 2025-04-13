// Action Cable provides the framework to deal with WebSockets in Rails.
// You can generate new channels where WebSocket features live using the `bin/rails generate channel` command.

import { createConsumer } from "@rails/actioncable";

// Create the consumer
const consumer = createConsumer();

// Log all ActionCable messages in development
if (import.meta.env.MODE === 'development') {
  consumer.subscriptions.create = function(channelName, config) {
    const originalReceived = config.received;
    config.received = function(data) {
      console.log('ActionCable Received:', channelName, data);
      if (originalReceived) originalReceived.call(this, data);
    };
    const subscription = createConsumer().subscriptions.create(channelName, config);
    console.log('ActionCable Subscription Created:', channelName);
    return subscription;
  };
  consumer.send = function(data) {
    console.log('ActionCable Sent:', data);
    createConsumer().send(data);
  };
}

export default consumer;
