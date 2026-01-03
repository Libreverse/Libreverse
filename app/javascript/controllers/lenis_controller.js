import { Controller } from "@hotwired/stimulus"
import Lenis from 'lenis'
import { gsap } from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'

gsap.registerPlugin(ScrollTrigger)

export default class extends Controller {
  static targets = ["content"]
  
  connect() {
    this.lenis = null
    this.boundDestroyIfNeeded = this.destroyIfNeeded.bind(this)
    this.boundDestroy = this.destroy.bind(this)
    this.handleTurboLoad = this.handleTurboLoad.bind(this)
    this.handleTurboRender = this.handleTurboRender.bind(this)
    
    this.setupEventListeners()
    this.init()
  }

  disconnect() {
    this.destroy()
    this.removeEventListeners()
  }

  init() {
    try {
      // Check if Lenis is available before initializing
      if (typeof Lenis === 'undefined') {
        console.error("Lenis is not available - library may not be loaded properly")
        return
      }

      this.lenis ||= new Lenis({
        duration: 1.2,
        easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
        direction: 'vertical',
        gestureDirection: 'vertical',
        smooth: true,
        mouseMultiplier: 1,
        smoothTouch: false,
        touchMultiplier: 2,
        infinite: false,
        autoResize: true,
        syncTouch: false,
        wheelMultiplier: 1,
        touchInertiaMultiplier: 35,
        touchInertiaExponent: 1.7,
        lerp: 0.15,           // Start here for snappy responsiveness (try 0.12–0.25 range)
        smoothWheel: true,    // Essential: smooths wheel/trackpad input without adding much inertia at higher lerp
        wheelMultiplier: 1.1, // Slightly >1 for direct, natural speed feel (optional, adjust 0.9–1.3)
        touchMultiplier: 2,   // Keeps mobile feeling native/responsive
        smoothTouch: false,   // Optional: disable on mobile if you want instant native touch scroll
        prevent: (node) => node.classList.contains('lenis-prevent') || node.hasAttribute('data-lenis-prevent')
      })

      // Expose globally for glass container integration
      window.lenis = this.lenis

      // Synchronize Lenis scrolling with GSAP's ScrollTrigger plugin
      this.lenis.on('scroll', ScrollTrigger.update)

      // Add Lenis's requestAnimationFrame (raf) method to GSAP's ticker
      // This ensures Lenis's smooth scroll animation updates on each GSAP tick
      gsap.ticker.add((time) => {
        this.lenis.raf(time * 1000) // Convert time from seconds to milliseconds
      })

      // Disable lag smoothing in GSAP to prevent any delay in scroll animations
      gsap.ticker.lagSmoothing(0)

      // Dispatch custom event when scroll updates (for compatibility with existing code)
      this.lenis.on('scroll', (args) => {
        const event = new CustomEvent('lenis-scroll', {
          detail: {
            scroll: args.scroll,
            limit: args.limit,
            velocity: args.velocity,
            direction: args.direction,
            progress: args.progress
          }
        })
        document.dispatchEvent(event)
      })

      // Start the animation loop
      this.raf()

    } catch (error) {
      console.error("Failed to initialize Lenis:", error)
      // Don't re-throw to prevent breaking the page load
    }
  }

  raf(time) {
    if (this.lenis) {
      this.lenis.raf(time)
      requestAnimationFrame(this.raf.bind(this))
    }
  }

  destroy() {
    if (this.lenis) {
      // Remove GSAP ticker integration
      gsap.ticker.remove(this.lenis.raf)
      
      // Destroy Lenis instance
      this.lenis.destroy()
      this.lenis = null
      
      // Clean up global reference
      window.lenis = null
    }
  }

  stop() {
    if (this.lenis) {
      this.lenis.stop()
    }
  }

  start() {
    if (this.lenis) {
      this.lenis.start()
    }
  }

  scrollTo(target, options = {}) {
    if (this.lenis) {
      this.lenis.scrollTo(target, options)
    }
  }

  resize() {
    if (this.lenis) {
      this.lenis.resize()
    }
  }

  destroyIfNeeded = (event) => {
    if (this.lenis && (!event || event.target.controller !== "Turbo.FrameController")) {
      this.destroy()
    }
  }

  handleTurboLoad = () => {
    if (this.lenis) {
      this.resize()
    } else {
      this.init()
    }
  }

  handleTurboRender = () => {
    if (!this.lenis) {
      this.init()
    } else {
      this.resize()
    }
  }

  setupEventListeners() {
    document.addEventListener("turbo:load", this.handleTurboLoad)
    document.addEventListener("turbo:before-cache", this.boundDestroyIfNeeded)
    document.addEventListener("turbo:before-render", this.boundDestroyIfNeeded)
    document.addEventListener("turbo:render", this.handleTurboRender)
    window.addEventListener("beforeunload", this.boundDestroy)
  }

  removeEventListeners() {
    document.removeEventListener("turbo:load", this.handleTurboLoad)
    document.removeEventListener("turbo:before-cache", this.boundDestroyIfNeeded)
    document.removeEventListener("turbo:before-render", this.boundDestroyIfNeeded)
    document.removeEventListener("turbo:render", this.handleTurboRender)
    window.removeEventListener("beforeunload", this.boundDestroy)
  }
}
