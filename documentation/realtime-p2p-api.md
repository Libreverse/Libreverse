# Realtime P2P + Yjs (Alpha)

<!-- markdownlint-disable MD046 -->

The Libreverse iframe environment injects a global collaborative + messaging API into experiences:

Globals:

- `P2P` / `LibreverseP2P` – messaging, peer roster, and collaborative doc access.
- Backed by ActionCable channels:
    - `WebsocketP2pChannel` – peer roster + generic messages only.
    - `SyncChannel` (yrb-actioncable) – Yjs CRDT synchronization.

## Architecture (WebSocket-based)

    Core components:

    1. WebSocket P2P Controller – manages P2P sessions and peer coordination
    2. WebSocket P2P Channel (ActionCable) – signaling and peer roster
    3. WebSocket P2P Connection – per-peer connection lifecycle
    4. P2P Frame custom element – hosts the experience iframe
    5. Client library – P2P/Yjs API surface for experiences

    Key features:

    - Pure WebSocket implementation (no WebRTC)
    - Backwards compatible with previous P2P API
    - Room-based connections with host/peer model
    - Automatic reconnection and heartbeat
    - Broadcast and direct messaging
    - Peer discovery and session management

## Basic Messaging

```js
P2P.onMessageCallback = (sender, payload) => {
    console.log("message from", sender, payload);
};
P2P.send({ kind: "ping" });
```

## Collaborative Document

A default document id = `session:<sessionId>` is auto-attached on init.

```js
P2P.onCollabReady((docId, ydoc) => {
    const ytext = ydoc.getText("shared");
    ytext.observe((event) => console.log("text changed", ytext.toString()));
    ytext.insert(0, "Hello world");
});
```

Attach an additional document:

```js
P2P.attachCollab("session:secondary");
```

## API Summary

| Method                   | Description                                                   |
| ------------------------ | ------------------------------------------------------------- |
| `send(data)`             | Broadcast payload to all peers.                               |
| `sendTo(peerId, data)`   | Direct message to a peer.                                     |
| `getPeers()`             | List of peer IDs.                                             |
| `getDoc()`               | The shared Y.Doc instance.                                    |
| `attachCollab(id)`       | Attach/sync a Yjs document (id namespace).                    |
| `detachCollab(id)`       | Destroy provider for given id.                                |
| `onCollabReady(handler)` | Callback when a doc syncs initial state. Returns unsubscribe. |

## Notes

- Persistence: Handled by yrb-actioncable's strategy (in-memory for alpha; durable backend can be added later).
- No custom size throttling yet; rely on typical Yjs small diff updates.
- Future: movement & presence layers may be reintroduced as separate lightweight messages or Yjs awareness integration.
