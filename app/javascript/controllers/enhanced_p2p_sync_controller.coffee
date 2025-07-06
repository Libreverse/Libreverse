import { Controller } from "@hotwired/stimulus"
import { useStore } from "stimulus-store"
import { p2pStore, toastStore, experienceStore } from "../stores"
import { P2pController } from "p2p"

###
Enhanced P2P Sync Controller with stimulus-store integration
Manages P2P connections with centralized state management
###
export default class extends P2pController
  @stores = [p2pStore, toastStore, experienceStore]

  @values = {
    # Connection settings
    autoReconnect: { type: Boolean, default: true },
    maxReconnectAttempts: { type: Number, default: 5 },
    reconnectDelay: { type: Number, default: 2000 },
    # Heartbeat settings
    heartbeatInterval: { type: Number, default: 30000 },
    connectionTimeout: { type: Number, default: 10000 },
  }

  connect: ->
    console.log "[EnhancedP2PSyncController] Connected"
    
    # Set up stimulus-store
    useStore(@)
    
    # Initialize P2P state
    @initializeP2PState()
    
    # Set up connection monitoring
    @setupConnectionMonitoring()
    
    # Call parent connect
    super()

  disconnect: ->
    console.log "[EnhancedP2PSyncController] Disconnecting"
    
    # Clean up monitoring
    @cleanupConnectionMonitoring()
    
    # Update store
    @updateP2PState({
      connectionState: "disconnected",
      connectedPeers: {}
    })
    
    super()

  initializeP2PState: ->
    # Initialize P2P store with current values
    @p2pStoreValue = {
      ...@p2pStoreValue,
      isEnabled: true,
      connectionState: "disconnected",
      connectedPeers: {},
      peerId: @peerId,
      hostPeerId: @hostPeerId,
      isHost: @iamHost
    }

  setupConnectionMonitoring: ->
    # Set up heartbeat for connection monitoring
    @heartbeatTimer = setInterval =>
      @sendHeartbeat() if @isConnected()
    , @heartbeatIntervalValue
    
    # Set up reconnection attempts tracking
    @reconnectAttempts = 0
    @reconnectTimer = undefined

  cleanupConnectionMonitoring: ->
    if @heartbeatTimer
      clearInterval(@heartbeatTimer)
      @heartbeatTimer = undefined
    
    if @reconnectTimer
      clearTimeout(@reconnectTimer)
      @reconnectTimer = undefined

  # P2P Controller overrides with state management
  p2pNegotiating: ->
    console.log "[EnhancedP2PSyncController] P2P Negotiating"
    
    @updateP2PState({
      connectionState: "negotiating"
    })
    
    @showToast("Connecting to peer...", "info")
    
    # Call custom negotiating handler
    @handleNegotiating()

  p2pConnecting: ->
    console.log "[EnhancedP2PSyncController] P2P Connecting"
    
    @updateP2PState({
      connectionState: "connecting"
    })
    
    @showToast("Establishing connection...", "info")
    
    # Call custom connecting handler
    @handleConnecting()

  p2pConnected: ->
    console.log "[EnhancedP2PSyncController] P2P Connected"
    
    @updateP2PState({
      connectionState: "connected",
      peerId: @peerId,
      hostPeerId: @hostPeerId,
      isHost: @iamHost
    })
    
    # Reset reconnect attempts
    @reconnectAttempts = 0
    
    @showToast("Connected to peer successfully!", "success")
    
    # Send initial state sync
    @sendInitialStateSync()
    
    # Call custom connected handler
    @handleConnected()

  p2pDisconnected: ->
    console.log "[EnhancedP2PSyncController] P2P Disconnected"
    
    @updateP2PState({
      connectionState: "disconnected",
      connectedPeers: {}
    })
    
    @showToast("Disconnected from peer", "warning")
    
    # Attempt reconnection if enabled
    if @autoReconnectValue and @reconnectAttempts < @maxReconnectAttemptsValue
      @scheduleReconnection()
    
    # Call custom disconnected handler
    @handleDisconnected()

  p2pClosed: ->
    console.log "[EnhancedP2PSyncController] P2P Closed"
    
    @updateP2PState({
      connectionState: "closed",
      connectedPeers: {}
    })
    
    @showToast("Connection closed", "info")
    
    # Call custom closed handler
    @handleClosed()

  p2pError: (error) ->
    console.error "[EnhancedP2PSyncController] P2P Error:", error
    
    @updateP2PState({
      connectionState: "error",
      lastError: error
    })
    
    @showToast("Connection error: #{error}", "error")
    
    # Call custom error handler
    @handleError(error)

  p2pReceivedMessage: (message) ->
    console.log "[EnhancedP2PSyncController] Received message:", message
    
    # Update last message in store
    @updateP2PState({
      lastMessage: {
        ...message,
        timestamp: Date.now()
      }
    })
    
    # Handle different message types
    switch message.type
      when "Data"
        @handleDataMessage(message)
      when "Data.Connection.State"
        @handleConnectionStateMessage(message)
      when "Experience.Sync"
        @handleExperienceSyncMessage(message)
      when "Experience.Update"
        @handleExperienceUpdateMessage(message)
      when "Heartbeat"
        @handleHeartbeatMessage(message)
      when "State.Sync"
        @handleStateSyncMessage(message)
      else
        @handleCustomMessage(message)

  # Message handlers
  handleDataMessage: (message) ->
    # Handle raw data message
    console.log "[EnhancedP2PSyncController] Data message:", message.data
    
    # Dispatch custom event for other controllers to handle
    @dispatchMessageEvent("p2p:data", message.data)

  handleConnectionStateMessage: (message) ->
    # Update connected peers state
    @updateP2PState({
      connectedPeers: message.data
    })
    
    console.log "[EnhancedP2PSyncController] Connection state updated:", message.data

  handleExperienceSyncMessage: (message) ->
    # Update experience store with synced data
    @experienceStoreValue = {
      ...@experienceStoreValue,
      ...message.data,
      multiplayerMode: true
    }
    
    @dispatchMessageEvent("p2p:experience:sync", message.data)

  handleExperienceUpdateMessage: (message) ->
    # Handle experience updates
    currentExperience = @experienceStoreValue
    
    @experienceStoreValue = {
      ...currentExperience,
      ...message.data,
      participants: message.data.participants || currentExperience.participants
    }
    
    @dispatchMessageEvent("p2p:experience:update", message.data)

  handleHeartbeatMessage: (message) ->
    # Respond to heartbeat
    @sendHeartbeatResponse(message.data.peerId)

  handleStateSyncMessage: (message) ->
    # Sync various application states
    if message.data.experience
      @experienceStoreValue = {
        ...@experienceStoreValue,
        ...message.data.experience
      }
    
    @dispatchMessageEvent("p2p:state:sync", message.data)

  handleCustomMessage: (message) ->
    # Handle custom message types
    @dispatchMessageEvent("p2p:message:#{message.type.toLowerCase()}", message.data)

  # Send methods with state management
  sendDataMessage: (data) ->
    message = {
      type: "Data",
      data: data,
      timestamp: Date.now(),
      peerId: @peerId
    }
    
    @p2pSendMessage(message)

  sendExperienceSync: (experienceData) ->
    message = {
      type: "Experience.Sync",
      data: experienceData,
      timestamp: Date.now(),
      peerId: @peerId
    }
    
    @p2pSendMessage(message)

  sendExperienceUpdate: (updateData) ->
    message = {
      type: "Experience.Update",
      data: updateData,
      timestamp: Date.now(),
      peerId: @peerId
    }
    
    @p2pSendMessage(message)

  sendHeartbeat: ->
    message = {
      type: "Heartbeat",
      data: {
        peerId: @peerId,
        timestamp: Date.now()
      }
    }
    
    @p2pSendMessage(message)

  sendHeartbeatResponse: (targetPeerId) ->
    message = {
      type: "Heartbeat.Response",
      data: {
        peerId: @peerId,
        targetPeerId: targetPeerId,
        timestamp: Date.now()
      }
    }
    
    @p2pSendMessage(message)

  sendInitialStateSync: ->
    # Send current experience state to new peer
    experienceData = @experienceStoreValue
    
    message = {
      type: "State.Sync",
      data: {
        experience: experienceData,
        timestamp: Date.now(),
        peerId: @peerId
      }
    }
    
    @p2pSendMessage(message)

  # Connection management
  scheduleReconnection: ->
    @reconnectAttempts++
    
    @showToast("Attempting to reconnect... (#{@reconnectAttempts}/#{@maxReconnectAttemptsValue})", "info")
    
    @reconnectTimer = setTimeout =>
      @attemptReconnection()
    , @reconnectDelayValue

  attemptReconnection: ->
    # Implement reconnection logic
    console.log "[EnhancedP2PSyncController] Attempting reconnection"
    
    # Reset connection state
    @updateP2PState({
      connectionState: "negotiating"
    })
    
    # Trigger reconnection through parent controller
    # This would depend on your P2P implementation

  # State management helpers
  updateP2PState: (updates) ->
    @p2pStoreValue = {
      ...@p2pStoreValue,
      ...updates
    }

  isConnected: ->
    @p2pStoreValue.connectionState is "connected"

  isHost: ->
    @p2pStoreValue.isHost

  getPeerId: ->
    @p2pStoreValue.peerId

  getConnectedPeers: ->
    @p2pStoreValue.connectedPeers

  # Utility methods
  showToast: (message, type = "info") ->
    currentToasts = @toastStoreValue
    newToast = {
      id: currentToasts.nextId,
      message,
      type,
      timeout: currentToasts.defaultTimeout,
      timestamp: Date.now()
    }
    
    updatedToasts = [...currentToasts.toasts, newToast]
    if updatedToasts.length > currentToasts.maxToasts
      updatedToasts = updatedToasts.slice(-currentToasts.maxToasts)
    
    @toastStoreValue = {
      ...currentToasts,
      toasts: updatedToasts,
      nextId: currentToasts.nextId + 1
    }

  dispatchMessageEvent: (eventName, data) ->
    event = new CustomEvent(eventName, {
      detail: data,
      bubbles: true
    })
    @element.dispatchEvent(event)

  # Custom handlers (can be overridden in subclasses)
  handleNegotiating: ->
    # Override in subclasses for custom negotiating behavior

  handleConnecting: ->
    # Override in subclasses for custom connecting behavior

  handleConnected: ->
    # Override in subclasses for custom connected behavior

  handleDisconnected: ->
    # Override in subclasses for custom disconnected behavior

  handleClosed: ->
    # Override in subclasses for custom closed behavior

  handleError: (error) ->
    # Override in subclasses for custom error handling

  # Public API for external access
  getCurrentP2PState: ->
    @p2pStoreValue

  sendCustomMessage: (type, data) ->
    message = {
      type: type,
      data: data,
      timestamp: Date.now(),
      peerId: @peerId
    }
    
    @p2pSendMessage(message)

  forceReconnect: ->
    @reconnectAttempts = 0
    @scheduleReconnection()

  getConnectionStats: ->
    {
      isConnected: @isConnected(),
      connectionState: @p2pStoreValue.connectionState,
      peerId: @p2pStoreValue.peerId,
      hostPeerId: @p2pStoreValue.hostPeerId,
      isHost: @p2pStoreValue.isHost,
      connectedPeers: Object.keys(@p2pStoreValue.connectedPeers).length,
      reconnectAttempts: @reconnectAttempts,
      lastMessage: @p2pStoreValue.lastMessage
    }
