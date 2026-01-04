import { Controller } from "@hotwired/stimulus"
import Lenis from 'lenis'

export default class extends Controller {
  static targets = ["content"]
  
  connect() {
    // please keep it hardcoded - it's really annoying to have to like try to set the flag before lenis initialises (else the logs won't be captured for startup phases)
    this.debug = false
    this.lenis = null
    this.disabled = false
    this.boundDestroyIfNeeded = this.destroyIfNeeded.bind(this)
    this.boundDestroy = this.destroy.bind(this)
    this.handleTurboLoad = this.handleTurboLoad.bind(this)
    this.handleTurboRender = this.handleTurboRender.bind(this)
    this._lastDebugScrollLogAt = 0
    this.boundDebugWheel = this.debugWheel.bind(this)
    this.boundDebugTouchMove = this.debugTouchMove.bind(this)
    
    window.__lenisWrapper = this.element
    window.__lenisWrapperDocument = this.element?.ownerDocument

    this.log("connect", { element: this.element })
    this.setupEventListeners()
    this.init()
  }

  disconnect() {
    this.log("disconnect")
    this.destroy()
    this.removeEventListeners()
  }

  init() {
    try {
      this.log("init:start")

      if (this.disabled) {
        this.log("init:skipped:disabled")
        return
      }

      // Check if Lenis is available before initializing
      if (typeof Lenis === 'undefined') {
        console.error("Lenis is not available - library may not be loaded properly")
        return
      }

      const contentElement = this.ensureContentElement()

      this.log("init:elements", {
        wrapper: this.element,
        content: contentElement,
        wrapperOverflow: getComputedStyle(this.element).overflow,
        wrapperOverflowY: getComputedStyle(this.element).overflowY
      })

      if (!contentElement) {
        this.log("init:warning:no_content_element", {
          expected: "Child element matching [data-lenis-content] or .lenis-content",
          wrapperInnerHTMLPreview: this.element.innerHTML?.slice?.(0, 300)
        })
      }

      this.log("init:dimensions", {
        wrapperClientHeight: this.element.clientHeight,
        wrapperScrollHeight: this.element.scrollHeight,
        contentClientHeight: contentElement?.clientHeight,
        contentScrollHeight: contentElement?.scrollHeight
      })

      // Apply Lenis to this controller's element (the lenis-wrapper)
      this.lenis ||= new Lenis({
        wrapper: this.element,
        content: contentElement || this.element,
        eventsTarget: this.element,
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

      this.log("init:created", { lenis: this.lenis })

      // Synchronize Lenis scrolling with custom scroll events
      this.lenis.on('scroll', (args) => {
        this.debugScroll("scroll", args)
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
      requestAnimationFrame(this.raf.bind(this))

      // Force a resize after first paint so Lenis computes a correct limit
      requestAnimationFrame(() => {
        if (!this.lenis) return
        this.lenis.resize()
        this.log("init:lenis_state", {
          scroll: this.lenis?.scroll,
          limit: this.lenis?.limit,
          isStopped: this.lenis?.isStopped
        })

        const wrapperClientHeight = this.element.clientHeight
        const wrapperScrollHeight = this.element.scrollHeight
        const shouldBeScrollable = wrapperScrollHeight > wrapperClientHeight + 1

        this.log("init:post_resize_dimensions", {
          wrapperClientHeight,
          wrapperScrollHeight,
          shouldBeScrollable,
          limit: this.lenis?.limit
        })

        if (shouldBeScrollable && (this.lenis?.limit ?? 0) === 0) {
          console.warn("[Lenis] Disabled: limit=0 even though wrapper has overflow. Falling back to native scroll.", {
            wrapperClientHeight,
            wrapperScrollHeight,
            wrapperOverflow: getComputedStyle(this.element).overflow,
            wrapperOverflowY: getComputedStyle(this.element).overflowY
          })
          this.disabled = true
          this.destroy()
        }
      })

      this.log("init:done")

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
      this.log("destroy")
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
    this.log("turbo:before:*", { type: event?.type, targetController: event?.target?.controller })
    if (this.lenis && (!event || event.target.controller !== "Turbo.FrameController")) {
      this.destroy()
    }
  }

  handleTurboLoad = () => {
    this.log("turbo:load")
    if (this.lenis) {
      this.resize()
    } else {
      this.init()
    }
  }

  handleTurboRender = () => {
    this.log("turbo:render")
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

    if (this.debug) {
      this.element.addEventListener("wheel", this.boundDebugWheel, { passive: true })
      this.element.addEventListener("touchmove", this.boundDebugTouchMove, { passive: true })
    }
  }

  removeEventListeners() {
    document.removeEventListener("turbo:load", this.handleTurboLoad)
    document.removeEventListener("turbo:before-cache", this.boundDestroyIfNeeded)
    document.removeEventListener("turbo:before-render", this.boundDestroyIfNeeded)
    document.removeEventListener("turbo:render", this.handleTurboRender)
    window.removeEventListener("beforeunload", this.boundDestroy)

    this.element.removeEventListener("wheel", this.boundDebugWheel)
    this.element.removeEventListener("touchmove", this.boundDebugTouchMove)
  }

  log(message, data = undefined) {
    if (!this.debug) return
    if (data !== undefined) {
      console.debug(`[Lenis] ${message}`, data)
      return
    }
    console.debug(`[Lenis] ${message}`)
  }

  debugScroll(message, args) {
    if (!this.debug) return

    const now = Date.now()
    if (now - this._lastDebugScrollLogAt < 250) return
    this._lastDebugScrollLogAt = now

    console.debug(`[Lenis] ${message}`, {
      scroll: args?.scroll,
      limit: args?.limit,
      velocity: args?.velocity,
      direction: args?.direction,
      progress: args?.progress
    })
  }

  debugWheel(event) {
    if (!this.debug) return

    const now = Date.now()
    if (now - this._lastDebugScrollLogAt < 250) return

    console.debug("[Lenis] wheel", {
      deltaX: event?.deltaX,
      deltaY: event?.deltaY,
      target: event?.target
    })
  }

  debugTouchMove(event) {
    if (!this.debug) return

    const now = Date.now()
    if (now - this._lastDebugScrollLogAt < 250) return

    console.debug("[Lenis] touchmove", {
      touches: event?.touches?.length,
      target: event?.target
    })
  }

  ensureContentElement() {
    let contentElement = this.element.querySelector('[data-lenis-content], .lenis-content')
    if (contentElement) return contentElement

    this.log("ensureContentElement:create")

    contentElement = document.createElement("div")
    contentElement.className = "lenis-content"
    contentElement.setAttribute("data-lenis-content", "")

    while (this.element.firstChild) {
      contentElement.appendChild(this.element.firstChild)
    }

    this.element.appendChild(contentElement)
    return contentElement
  }
}
