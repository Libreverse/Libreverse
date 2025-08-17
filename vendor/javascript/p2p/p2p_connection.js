// @ts-nocheck
import { ConnectionState, MessageType } from "p2p/message"

const ICE_CONFIG = {
    iceServers: [
        {
            urls: ["stun:stun.l.google.com:19302", "stun:stun1.l.google.com:19302", "stun:stun2.l.google.com:19302"]
        },
    ],
}

export default class P2pConnection {
    constructor(peer, clientId, hostId, iamHost, iceConfig, heartbeatConfig) { // TODO: add heartbeatInterval to config
        this.peer = peer
        this.clientId = clientId
        this.hostId = hostId
        this.iamHost = iamHost
        this.state = ConnectionState.New
        this.lastTimeUpdate = 0
        this.iceConfig = iceConfig || ICE_CONFIG
        this.heartbeatConfig = (heartbeatConfig && typeof heartbeatConfig === 'object')
            ? { interval_mls: 10000, idle_timeout_mls: 30000, ...heartbeatConfig }
            : null
        this.heartbeat = null
        this.sendDataChannel = null
        this.receiveDataChannel = null
        this.sendDataChannelOpen = false
        this.rtcPeerConnection = null
    }

    setupRTCPeerConnection() {
        // console.log("connection start ...")
        this.rtcPeerConnection = new RTCPeerConnection(this.iceConfig)

        this.rtcPeerConnection.onicecandidate = event => {
            // console.log(event)
            if (event.candidate) {
                let ice = {}
                ice[ConnectionState.IceCandidate] = event.candidate
                this.peer.signal(ConnectionState.IceCandidate, ice)
            }
        }
        this.rtcPeerConnection.oniceconnectionstatechange = () => {
            // optional: handle ICE connection state changes
        }

        this.rtcPeerConnection.onconnectionstatechange = () => {
            // console.log(`onconnectionstatechange ${this.rtcPeerConnection.connectionState}`)
            this.state = this.rtcPeerConnection.connectionState
            if (this.state == ConnectionState.DisConnected || this.state == ConnectionState.Closed) {
                this.close()
            }
            this.peer.updateP2pConnectionState(this)
        }

        this.sendDataChannel = this.rtcPeerConnection.createDataChannel("sendChannel")
        this.sendDataChannelOpen = false
        this.sendDataChannel.onopen = this.handleSendChannelStatusChange.bind(this)
        this.sendDataChannel.onclose = this.handleSendChannelStatusChange.bind(this)

        this.rtcPeerConnection.ondatachannel = event => {
            // console.log("ondatachannel p2p ...")
            this.receiveDataChannel = event.channel
            this.receiveDataChannel.onmessage = this.receiveP2pMessage.bind(this)
            this.receiveDataChannel.onopen = this.handleReceiveChannelStatusChange.bind(this)
            this.receiveDataChannel.onclose = this.handleReceiveChannelStatusChange.bind(this)

            this.peer.updateP2pConnectionState(this)
        }

        return this.rtcPeerConnection
    }

    receiveP2pMessage(event) {
        // console.log(`p2p received msg: ${event.data}`)
        let msg
        try {
            msg = JSON.parse(event.data)
        } catch (_e) {
            return
        }
        if (!msg || typeof msg !== 'object' || !msg.type) {
            return
        }
        switch (msg.type) {
            case MessageType.Heartbeat:
                this.state = ConnectionState.Connected
                this.lastTimeUpdate = Date.now()
                break
            default:
                this.peer.receivedP2pMessage(msg)
                break
        }
    }

    sendP2pMessage(message, type = MessageType.Data, senderId = null) {
        if (this.sendDataChannel && this.sendDataChannelOpen) {
            const msgJson = JSON.stringify({
                type: type,
                senderId: senderId || this.peer.peerId,
                data: message
            })
            this.sendDataChannel.send(msgJson)
        }
    }

    handleSendChannelStatusChange(_event) {
        // console.log(event)
        if (this.sendDataChannel) {
            const open = this.sendDataChannel.readyState === "open"
            this.sendDataChannelOpen = open
            if (open && this.heartbeatConfig) {
                this.scheduleHeartbeat()
            } else {
                this.stopHeartbeat()
            }
        }
        this.peer.updateP2pConnectionState(this)
    }

    handleReceiveChannelStatusChange(_event) {
        // no-op placeholder to keep symmetry and avoid missing handler
        this.peer.updateP2pConnectionState(this)
    }

    scheduleHeartbeat() {
        if (!this.heartbeatConfig || typeof this.heartbeatConfig.interval_mls !== 'number' || this.heartbeatConfig.interval_mls <= 0) {
            return
        }
        clearTimeout(this.heartbeat)
        this.heartbeat = setTimeout(() => this.sendHeartbeat(), this.heartbeatConfig.interval_mls)
    }

    sendHeartbeat() {
        if (!this.heartbeatConfig) return
        const idle = this.heartbeatConfig.idle_timeout_mls
        if (
            this.lastTimeUpdate > 0 &&
            typeof idle === 'number' &&
            idle > 0 &&
            Date.now() - this.lastTimeUpdate > idle
        ) {
            // console.log("HEART-BEAT DETECT DISCONNECTED ............")
            this.state = ConnectionState.DisConnected
            this.peer.updateP2pConnectionState(this)
            this.close()
        } else {
            this.sendP2pMessage("ping", MessageType.Heartbeat)
            this.scheduleHeartbeat()
        }
    }

    stopHeartbeat() {
        // console.log(`stop heartbeat ${this.hostId} <-> ${this.clientId}`)
        clearTimeout(this.heartbeat)
    }

    close() {
        // console.log(`close the connection ${this.hostId} <-> ${this.clientId}`)
        this.stopHeartbeat()
        try { this.sendDataChannel && this.sendDataChannel.close() } catch (_e) {}
        try { this.receiveDataChannel && this.receiveDataChannel.close() } catch (_e) {}
        try { this.rtcPeerConnection && this.rtcPeerConnection.close() } catch (_e) {}
        this.state = ConnectionState.Closed
        this.peer.updateP2pConnectionState(this)
    }
}
