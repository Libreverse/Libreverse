###
# RaindropController
#
# Usage:
#   <div data-controller="raindrop"
#        data-raindrop-background-url-value="..."
#        data-raindrop-rainyday-options-value="{&quot;blur&quot;:5, &quot;fps&quot;:30}">
#     <canvas class="raindrop-canvas"></canvas>
#   </div>
#
# The 'rainydayOptions' value can be set to any RainyDay.js options (see library docs).
###
import ApplicationController from "./application_controller"
import "../libs/rainyday.js"

###*
 * Manages an iframe containing the RaindropFX effect to isolate its context.
###
export default class extends ApplicationController
  @values =
    backgroundUrl: String
    rainydayOptions: { type: Object, default: {} }

  connect: ->
    super.connect()
    @setupRainyDay()
    return

  disconnect: ->
    super.disconnect()
    @rainyday?.destroy()
    @rainyday = null
    return

  setupRainyDay: ->
    unless @hasBackgroundUrlValue
      return

    # Remove any previous canvas
    for child in @element.children
      if child.tagName?.toLowerCase() is 'canvas'
        child.remove()

    img = new window.Image()
    img.crossOrigin = "anonymous"
    img.src = @backgroundUrlValue

    img.onload = =>
      # Create a canvas that fills the parent
      canvas = document.createElement('canvas')
      canvas.width = @element.offsetWidth
      canvas.height = @element.offsetHeight
      canvas.style.position = 'absolute'
      canvas.style.top = 0
      canvas.style.left = 0
      canvas.style.width = '100%'
      canvas.style.height = '100%'
      canvas.style.pointerEvents = 'none'
      canvas.className = 'raindrop-canvas'
      @element.appendChild(canvas)

      # Default config matching raindrop-fx as closely as possible
      defaultRainyDayOptions =
        opacity: 1
        blur: 20
        fps: 120
        enableCollisions: true
        enableSizeChange: true
        gravityThreshold: 3
        gravityAngle: Math.PI / 2
        gravityAngleVariance: 0
        reflectionScaledownFactor: 5
        reflectionDropMappingWidth: 80
        reflectionDropMappingHeight: 80
        width: canvas.width
        height: canvas.height
        position: 'absolute'
        top: 0
        left: 0
        parentElement: @element
        canvas: canvas
        image: img

      # Merge options: background image, parent, canvas, size, plus user config
      options = Object.assign {}, defaultRainyDayOptions, @rainydayOptionsValue

      @rainyday = new window.RainyDay(options)

      min = 8
      base = 8
      rate = 1
      speed = 25
      @rainyday.rain([[min, base, rate]], speed)
    return
