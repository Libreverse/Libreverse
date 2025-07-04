import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "canvas"]

  connect() {
    this.NUM_PARTICLES = 50
    this.MAX_Z = 2
    this.MAX_R = 2
    this.Z_SPD = 2
    this.PARTICLES = []
    this.isGoing = false
    
    this.initializeCanvas()
    this.createParticles()
    this.startLoop()
  }

  disconnect() {
    if (this.animationId) {
      cancelAnimationFrame(this.animationId)
    }
  }

  initializeCanvas() {
    if (this.hasCanvasTarget) {
      this.canvas = this.canvasTarget
    } else {
      // Create canvas if it doesn't exist
      this.canvas = document.createElement('canvas')
      this.canvas.style.position = 'absolute'
      this.canvas.style.top = '0px'
      this.canvas.style.left = '0px'
      this.canvas.style.width = 'calc(100% - 0px)'
      this.canvas.style.height = 'calc(100% - 0px)'
      this.canvas.style.pointerEvents = 'none'
      this.canvas.style.zIndex = '-1'
      this.canvas.style.borderRadius = '8px'
      this.buttonTarget.style.position = 'relative'
      this.buttonTarget.style.overflow = 'hidden'
      this.buttonTarget.append(this.canvas)
    }
    
    this.ctx = this.canvas.getContext("2d")
    this.W = this.canvas.width = this.buttonTarget.offsetWidth - 4
    this.H = this.canvas.height = this.buttonTarget.offsetHeight - 4
    this.XO = this.W / 2
    this.YO = this.H / 2
  }

  createParticles() {
    this.PARTICLES = []
    for (let index = 0; index < this.NUM_PARTICLES; index++) {
      const X = Math.random() * this.W
      const Y = Math.random() * this.H
      const Z = Math.random() * this.MAX_Z
      this.PARTICLES.push(new Particle(X, Y, Z))
    }
  }

  startLoop() {
    this.loop()
  }

  loop() {
    this.animationId = requestAnimationFrame(() => this.loop())
    
    this.ctx.fillStyle = "rgba(35,35,35,0.15)"
    this.ctx.fillRect(0, 0, this.W, this.H)
    this.render()
  }

  render() {
    for (let index = 0; index < this.PARTICLES.length; index++) {
      this.PARTICLES[index].render(this.ctx, this.W, this.H, this.XO, this.YO, this.MAX_Z, this.MAX_R)
    }
  }

  toggle() {
    if (this.isGoing) {
      this.isGoing = false
      this.buttonTarget.classList.remove("hyperspace-active")
    } else {
      this.isGoing = true
      this.buttonTarget.classList.add("hyperspace-active")
    }
  }
}

class Particle {
  constructor(x, y, z) {
    this.pos = new Vector(x, y, z)
    const X_VEL = 0
    const Y_VEL = 0
    const Z_VEL = -2 // Z_SPD
    this.vel = new Vector(X_VEL, Y_VEL, Z_VEL)
    this.vel.scale(0.01)
    this.fill = "rgba(216,214,213,0.8)"
    this.stroke = this.fill
  }

  update() {
    this.pos.add(this.vel)
  }

  render(context, W, H, XO, YO, MAX_Z, MAX_R) {
    const PIXEL = this.to2d(XO, YO)
    const X = PIXEL[0]
    const Y = PIXEL[1]
    const R = ((MAX_Z - this.pos.z) / MAX_Z) * MAX_R

    if (X < 0 || X > W || Y < 0 || Y > H) {
      this.pos.z = MAX_Z
    }

    this.update()
    context.beginPath()
    context.fillStyle = this.fill
    context.strokeStyle = this.stroke
    context.arc(X, Y, R, 0, Math.PI * 2)
    context.fill()
    context.stroke()
    context.closePath()
  }

  to2d(XO, YO) {
    const X_COORD = this.pos.x - XO
    const Y_COORD = this.pos.y - YO
    const PX = X_COORD / this.pos.z
    const PY = Y_COORD / this.pos.z
    return [PX + XO, PY + YO]
  }
}

class Vector {
  constructor(x, y, z) {
    this.x = x
    this.y = y
    this.z = z
  }

  add(v) {
    this.x += v.x
    this.y += v.y
    this.z += v.z
  }

  scale(n) {
    this.x *= n
    this.y *= n
    this.z *= n
  }
}
