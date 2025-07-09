# WebSocket P2P Implementation

A modern P2P implementation using pure WebSockets that maintains backwards compatibility with the previous P2P API.

## Architecture

### Core Components

1. **WebSocket P2P Controller** - Main controller that manages P2P connections
2. **WebSocket P2P Channel** - ActionCable channel for signaling and coordination
3. **WebSocket P2P Connection** - Individual peer connection management
4. **WebSocket P2P Frame** - Custom element for hosting P2P content
5. **Client Library** - JavaScript API for experiences to use P2P features

### Key Features

- Pure WebSocket implementation (no WebRTC dependencies)
- Backwards compatible API with previous P2P system
- Room-based connections with host/peer model
- Automatic reconnection and heartbeat
- Message broadcasting and direct messaging
- Session management and peer discovery

## Usage

Same as the previous P2P system - no changes required for existing experiences.

```html
<p2p-frame session-id="session_123" peer-id="peer_456">
    <iframe src="/experience"></iframe>
</p2p-frame>
```

The experience can use the same P2P API:

```javascript
// In experience iframe
P2P.send({ type: "game_move", data: { x: 10, y: 20 } });

P2P.onMessage = (senderId, data) => {
    console.log("Received from", senderId, ":", data);
};
```
