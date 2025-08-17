import { ConnectionState, MessageType } from "p2p/message"
import P2pConnection from "p2p/p2p_connection"

export default class P2pPeer {
    constructor(sessionId, peerId, container, signaling, iceConfig, heartbeatConfig) {
        this.sessionId = sessionId
        this.container = container
        this.signaling = signaling
        this.iceConfig = iceConfig
        this.heartbeatConfig = heartbeatConfig
        this.peerId = peerId
        this.hostPeerId = null
        this.iamHost = false
        this.state = null
    }

    setup() {
        this.connections = new Map()
        this.signal(ConnectionState.SessionJoin, {})
        this.dispatchP2pConnectionState({ state: ConnectionState.Connecting })
    }

    signal(state, data) {
        const msg = {
            type: MessageType.Connection,
            session_id: this.sessionId,
            peer_id: this.peerId,
            state,
            ...data
        }
        this.signaling.send(msg)
    }

    negotiate(msg) {
        switch (msg.state) {
            case ConnectionState.SessionJoin:
                break
            case ConnectionState.SessionReady:
                if (msg.host_peer_id === this.peerId) { // I am host
                    this.iamHost = true
                    this.hostPeerId = this.peerId

                    if (msg.peer_id === this.peerId) {
                        this.updateP2pConnectionState()
                        return
                    }

                    const connection = new P2pConnection(this, msg.peer_id, this.peerId, this.iamHost, this.iceConfig, this.heartbeatConfig)
                    this.connections.set(msg.peer_id, connection)

                    let rtcPeerConnection
                    try {
                        rtcPeerConnection = connection.setupRTCPeerConnection()
                    } catch (err) {
                        this._handleConnectionSetupFailure(err, connection, { peerKey: msg.peer_id, role: 'host', host_peer_id: this.peerId, remote_peer_id: msg.peer_id })
                        return
                    }

                    rtcPeerConnection.createOffer()
                        .then(offer => rtcPeerConnection.setLocalDescription(offer))
                        .then(() => {
                            const offer = { host_peer_id: msg.host_peer_id }
                            offer[ConnectionState.SdpOffer] = JSON.stringify(rtcPeerConnection.localDescription)
                            this.signal(ConnectionState.SdpOffer, offer)
                        })
                        .catch(err => {
                            console.error('Failed to create offer:', err)
                            connection.state = ConnectionState.Failed
                            this.updateP2pConnectionState(connection)
                        })
                }

                this.state = ConnectionState.SessionReady
                break

            case ConnectionState.SdpOffer:
                if (msg.host_peer_id !== this.peerId && this.state !== ConnectionState.SdpOffer) { // I am not host
                    this.hostPeerId = msg.host_peer_id
                    const connection = new P2pConnection(this, this.peerId, msg.host_peer_id, this.iamHost, this.iceConfig, this.heartbeatConfig)
                    this.connections.set(this.peerId, connection)

                    let rtcPeerConnection
                    try {
                        rtcPeerConnection = connection.setupRTCPeerConnection()
                    } catch (err) {
                        this._handleConnectionSetupFailure(err, connection, { peerKey: this.peerId, role: 'client', host_peer_id: msg.host_peer_id, remote_peer_id: msg.host_peer_id })
                        return
                    }

                    const rawOffer = msg[ConnectionState.SdpOffer]
                    let offer
                    try {
                        offer = JSON.parse(rawOffer)
                    } catch (e) {
                        const errorInfo = {
                            error: 'Malformed JSON in SdpOffer',
                            peer_id: this.peerId,
                            host_peer_id: msg.host_peer_id,
                            raw_message: rawOffer
                        }
                        console.error('[P2pPeer]', errorInfo, e)
                        this.signal(ConnectionState.Error, { context: 'SdpOffer', ...errorInfo })
                        return
                    }

                    rtcPeerConnection.setRemoteDescription(new RTCSessionDescription(offer))
                        .then(() => rtcPeerConnection.createAnswer())
                        .then(answer => rtcPeerConnection.setLocalDescription(answer))
                        .then(() => {
                            const answer = { host_peer_id: msg.host_peer_id }
                            answer[ConnectionState.SdpAnswer] = JSON.stringify(rtcPeerConnection.localDescription)
                            this.signal(ConnectionState.SdpAnswer, answer)
                        })
                        .catch(err => {
                            console.error('Failed to handle SdpOffer:', err)
                            connection.state = ConnectionState.Failed
                            this.updateP2pConnectionState(connection)
                        })

                    this.state = ConnectionState.SdpOffer
                }
                break

            case ConnectionState.SdpAnswer:
                if (msg.host_peer_id === this.peerId) { // I am host
                    const clientConnection = this.connections.get(msg.peer_id)
                    if (!clientConnection) return

                    const rtcPeerConnection = clientConnection.rtcPeerConnection
                    const rawAnswer = msg[ConnectionState.SdpAnswer]
                    let answer
                    try {
                        answer = JSON.parse(rawAnswer)
                    } catch (e) {
                        const errorInfo = {
                            error: 'Malformed JSON in SdpAnswer',
                            peer_id: this.peerId,
                            client_peer_id: msg.peer_id,
                            raw_message: rawAnswer
                        }
                        console.error('[P2pPeer]', errorInfo, e)
                        this.signal(ConnectionState.Error, { context: 'SdpAnswer', ...errorInfo })
                        return
                    }

                    rtcPeerConnection.setRemoteDescription(new RTCSessionDescription(answer))
                        .catch(err => console.error('Failed to set remote description (answer):', err))
                }
                break

            case ConnectionState.IceCandidate:
                if (msg[ConnectionState.IceCandidate]) {
                    this.connections.forEach((connection) => {
                        connection.rtcPeerConnection.addIceCandidate(new RTCIceCandidate(msg[ConnectionState.IceCandidate]))
                            .catch(err => console.error('Failed to add ICE candidate:', err))
                    })
                }
                break

            case ConnectionState.Error:
                break

            default:
                break
        }
    }

    dispatchP2pMessage(message, type, senderId) {
        this.connections.forEach((connection) => {
            connection.sendP2pMessage(message, type, senderId)
        })
    }

    sendP2pMessage(message) {
        if (this.iamHost) {
            this.container.dispatchP2pMessage({
                type: MessageType.Data,
                senderId: this.peerId,
                data: message
            })
        }

        this.connections.forEach((connection) => {
            connection.sendP2pMessage(message, MessageType.Data, this.peerId)
        })
    }

    receivedP2pMessage(message) {
        switch (message.type) {
            case MessageType.Data:
            case MessageType.DataConnectionState:
                if (this.iamHost) {
                    this.dispatchP2pMessage(message.data, message.type, message.senderId)
                }
                this.container.dispatchP2pMessage(message)
                break
            default:
                break
        }
    }

    updateP2pConnectionState(connection = null) {
        if (this.iamHost) {
            this.connectionStatus = this.connectionStatus || {}
            this.connections.forEach((connection, peerId) => {
                this.connectionStatus[peerId] = connection.state
            })
            this.connectionStatus[this.hostPeerId] = ConnectionState.Connected

            this.container.dispatchP2pMessage({
                type: MessageType.DataConnectionState,
                senderId: this.peerId,
                data: this.connectionStatus
            })

            this.dispatchP2pMessage(this.connectionStatus, MessageType.DataConnectionState, this.hostPeerId)
        }

        if (connection) {
            this.dispatchP2pConnectionState(connection)
        }
    }

    dispatchP2pConnectionState(connection) {
        switch (connection.state) {
            case ConnectionState.Connecting:
                this.container.p2pConnecting()
                break
            case ConnectionState.Connected:
                this.container.p2pConnected()
                break
            case ConnectionState.DisConnected:
                this.container.p2pDisconnected()
                break
            case ConnectionState.Closed:
                this.container.p2pClosed()
                break
            case ConnectionState.Failed:
                this.container.p2pError()
                break
            default:
                break
        }
    }

    _handleConnectionSetupFailure(err, connection, meta = {}) {
        const { peerKey, role, host_peer_id, remote_peer_id } = meta || {}
        const errorInfo = {
            error: 'Failed to setup RTCPeerConnection',
            peer_id: this.peerId,
            role,
            host_peer_id,
            remote_peer_id,
            details: err && (err.message || String(err))
        }
        console.error('[P2pPeer]', errorInfo)

        try { connection && connection.close && connection.close() } catch (_e) {}
        if (peerKey && this.connections && this.connections.has(peerKey)) {
            try { this.connections.delete(peerKey) } catch (_e) {}
        }

        if (this.container && typeof this.container.p2pError === 'function') {
            try { this.container.p2pError() } catch (_e) {}
        }

        this.signal(ConnectionState.Error, { context: 'SetupRTCPeerConnection', ...errorInfo })
    }
}
