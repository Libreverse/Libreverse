{ Controller } = require '@hotwired/stimulus'
LocomotiveScroll = require 'locomotive-scroll'
class DefaultExport extends Controller
  connect: ->
    @scroll = undefined
    @boundDestroyIfNeeded = @destroyIfNeeded.bind(@)
    @boundDestroy = @destroy.bind(@)
    @handleTurboLoad = @handleTurboLoad.bind(@)
    @handleTurboRender = @handleTurboRender.bind(@)
    @setupEventListeners()
    @init()


  disconnect: ->
    @destroy()
    @removeEventListeners()


  init: ->
    try
      @scroll ||= new LocomotiveScroll({
        el: @element or document.querySelector('[data-scroll-container]') or document.body,
        smooth: true,
        repeat: true,
        gestureDirection: 'vertical',
        reloadOnContextChange: false,
        resetNativeScroll: false,
        smartphone: {
          smooth: true
        },
        tablet: {
          smooth: true
        }
      })

      # Expose globally for glass container integration
      window.locomotiveScroll = @scroll

      # Dispatch custom event when scroll updates
      @scroll.on 'scroll', (args) =>
        event = new CustomEvent('locomotive-scroll', {
          detail: args
        })
        document.dispatchEvent(event)
    catch error
      console.error "Failed to initialize LocomotiveScroll:", error


  destroy: ->
    if @scroll?
      @scroll.destroy()
      @scroll = undefined
      # Clean up global reference
      window.locomotiveScroll = undefined


  resume: ->
    if @scroll?
      @scroll.update()


  destroyIfNeeded: (event) =>
    if @scroll? and (not event or event.target.controller isnt "Turbo.FrameController")
      @destroy()


  handleTurboLoad: =>
    if @scroll?
      @resume()
    else
      @init()


  handleTurboRender: =>
    unless @scroll?
      @init()


  setupEventListeners: ->
    document.addEventListener "turbo:load", @handleTurboLoad
    document.addEventListener "turbo:before-cache", @boundDestroyIfNeeded
    document.addEventListener "turbo:before-render", @boundDestroyIfNeeded
    document.addEventListener "turbo:render", @handleTurboRender
    window.addEventListener "beforeunload", @boundDestroy


  removeEventListeners: ->
    document.removeEventListener "turbo:load", @handleTurboLoad
    document.removeEventListener "turbo:before-cache", @boundDestroyIfNeeded
    document.removeEventListener "turbo:before-render", @boundDestroyIfNeeded
    document.removeEventListener "turbo:render", @handleTurboRender
    window.removeEventListener "beforeunload", @boundDestroy


module.exports = DefaultExport
