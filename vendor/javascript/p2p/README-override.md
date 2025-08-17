# Note: Backend-only usage

We use the gem's backend signaling channels only.

The generated frontend under this directory is not used because the app already
has a Stimulus controller (`websocket_p2p_controller.coffee`) and Yjs/y-webrtc
client (`websocket_p2p_client.js`).

If you prefer to swap to the vendor frontend, wire it via your bundler and
remove the app-specific controllers.
