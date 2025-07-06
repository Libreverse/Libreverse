import { Controller } from "@hotwired/stimulus"

###
Copyright (c) 2025 by Maurice Melchers (https://codepen.io/mephysto/pen/poKNxoY)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
###

export default class extends Controller
  @targets = ["button", "canvas"]

  connect: ->
    @NUM_PARTICLES = 50
    @MAX_Z = 2
    @MAX_R = 2
    @Z_SPD = 2
    @PARTICLES = []
    @isGoing = false

    @initializeCanvas()
    @createParticles()
    @startLoop()

  disconnect: ->
    if @animationId
      cancelAnimationFrame @animationId

  initializeCanvas: ->
    if @hasCanvasTarget
      @canvas = @canvasTarget
    else
      # Create canvas if it doesn't exist
      @canvas = document.createElement "canvas"
      @canvas.style.position = "absolute"
      @canvas.style.top = "0px"
      @canvas.style.left = "0px"
      @canvas.style.width = "calc(100% - 0px)"
      @canvas.style.height = "calc(100% - 0px)"
      @canvas.style.pointerEvents = "none"
      @canvas.style.zIndex = "-1"
      @canvas.style.borderRadius = "8px"
      @buttonTarget.style.position = "relative"
      @buttonTarget.style.overflow = "hidden"
      @buttonTarget.append @canvas

    @ctx = @canvas.getContext "2d"
    @W = @canvas.width = @buttonTarget.offsetWidth - 4
    @H = @canvas.height = @buttonTarget.offsetHeight - 4
    @XO = @W / 2
    @YO = @H / 2

  createParticles: ->
    @PARTICLES = []
    for index in [0...@NUM_PARTICLES]
      X = Math.random() * @W
      Y = Math.random() * @H
      Z = Math.random() * @MAX_Z
      @PARTICLES.push new Particle(X, Y, Z)

  startLoop: ->
    @loop()

  loop: ->
    @animationId = requestAnimationFrame => @loop()

    @ctx.fillStyle = "rgba(35,35,35,0.15)"
    @ctx.fillRect 0, 0, @W, @H
    @render()

  render: ->
    for index in [0...@PARTICLES.length]
      @PARTICLES[index].render(
        @ctx,
        @W,
        @H,
        @XO,
        @YO,
        @MAX_Z,
        @MAX_R,
      )

  toggle: ->
    if @isGoing
      @isGoing = false
      @buttonTarget.classList.remove "hyperspace-active"
    else
      @isGoing = true
      @buttonTarget.classList.add "hyperspace-active"

class Particle
  constructor: (x, y, z) ->
    @pos = new Vector(x, y, z)
    X_VEL = 0
    Y_VEL = 0
    Z_VEL = -2 # Z_SPD
    @vel = new Vector(X_VEL, Y_VEL, Z_VEL)
    @vel.scale 0.01
    @fill = "rgba(216,214,213,0.8)"
    @stroke = @fill

  update: ->
    @pos.add @vel

  render: (context, W, H, XO, YO, MAX_Z, MAX_R) ->
    PIXEL = @to2d(XO, YO)
    X = PIXEL[0]
    Y = PIXEL[1]
    R = ((MAX_Z - @pos.z) / MAX_Z) * MAX_R

    if X < 0 or X > W or Y < 0 or Y > H
      @pos.z = MAX_Z

    @update()
    context.beginPath()
    context.fillStyle = @fill
    context.strokeStyle = @stroke
    context.arc X, Y, R, 0, Math.PI * 2
    context.fill()
    context.stroke()
    context.closePath()

  to2d: (XO, YO) ->
    X_COORD = @pos.x - XO
    Y_COORD = @pos.y - YO
    PX = X_COORD / @pos.z
    PY = Y_COORD / @pos.z
    [PX + XO, PY + YO]

class Vector
  constructor: (x, y, z) ->
    @x = x
    @y = y
    @z = z

  add: (v) ->
    @x += v.x
    @y += v.y
    @z += v.z

  scale: (n) ->
    @x *= n
    @y *= n
    @z *= n
