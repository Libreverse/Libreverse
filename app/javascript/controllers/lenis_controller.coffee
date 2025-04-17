import { Controller } from "@hotwired/stimulus"
import Lenis from "lenis"

export default class extends Controller
  connect: ->
    @lenis = undefined
    # Bind the event handlers once to preserve references
    @boundDestroyIfNeeded = @destroyIfNeeded.bind(@)
    @boundDestroy = @destroy.bind(@)
    @handleTurboLoad = @handleTurboLoad.bind(@)
    @handleTurboRender = @handleTurboRender.bind(@)
    @setupEventListeners()
    @init()
    return

  disconnect: ->
    @destroy()
    @removeEventListeners()
    return

  init: ->
    try
      @lenis ||= new Lenis({
        duration: 1.2,
        easing: (t) -> Math.min(1, 1.001 - Math.pow(2, -10 * t)),
        touchMultiplier: 2,
        infinite: false,
        autoRaf: true,
      })
    catch error
      console.error "Failed to initialize Lenis:", error
    return

  destroy: ->
    if @lenis
      @lenis.destroy()
      @lenis = undefined
    return

  resume: ->
    if @lenis
      @lenis.start()
    return

  destroyIfNeeded: (event) ->
    if @lenis and (!event or event.target.controller != "Turbo.FrameController")
      @destroy()
    return

  handleTurboLoad: => # Use fat arrow for proper `this` context
    if @lenis
      @resume()
    else
      @init()
    return

  handleTurboRender: => # Use fat arrow for proper `this` context
    unless @lenis
      @init()
    return

  setupEventListeners: ->
    document.addEventListener "turbo:load", @handleTurboLoad
    document.addEventListener "turbo:before-cache", @boundDestroyIfNeeded
    document.addEventListener "turbo:before-render", @boundDestroyIfNeeded
    document.addEventListener "turbo:render", @handleTurboRender
    window.addEventListener "beforeunload", @boundDestroy
    return

  removeEventListeners: ->
    document.removeEventListener "turbo:load", @handleTurboLoad
    document.removeEventListener "turbo:before-cache", @boundDestroyIfNeeded
    document.removeEventListener "turbo:before-render", @boundDestroyIfNeeded
    document.removeEventListener "turbo:render", @handleTurboRender
    window.removeEventListener "beforeunload", @boundDestroy
    return