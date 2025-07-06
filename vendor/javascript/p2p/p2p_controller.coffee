import { Controller } from "@hotwired/stimulus"

export default class extends Controller
  connect: ->
    @p2pSetup()

  p2pSetup: ->
    @p2pFrame = @element.closest "p2p-frame"
    if @p2pFrame
      @p2pFrame.setP2pListener @
    else
      throw new Error "Couldn't find p2p-frame!"

  get peerId: ->
    @p2pFrame.peer?.peerId
    
  get hostPeerId: ->
    @p2pFrame.peer?.hostPeerId

  get iamHost: ->
    @p2pFrame.peer?.iamHost

  # p2p callbacks
  
  p2pNegotiating: ->

  p2pConnecting: ->

  p2pConnected: ->

  p2pDisconnected: ->

  p2pClosed: ->

  p2pError: ->

  # send/received p2p message

  p2pSendMessage: (message) ->
    if @p2pFrame
      @p2pFrame.sendP2pMessage message

  p2pReceivedMessage: (message) ->
