import { Controller } from "@hotwired/stimulus"
import { renderLiquidGlassNav, renderLiquidGlassSidebarRightRounded, validateLiquidGlass } from "../libs/liquid_glass.js"
import { Turbo } from "@hotwired/turbo-rails"

/**
 * Base Glass Controller - can be extended by other controllers for liquid glass effects
 * 
 * Usage:
 * 1. Add data-controller="glass" to any element
 * 2. Configure with data-glass-*-value attributes
 * 3. Optionally extend this controller for custom behavior
 */
export default class extends Controller {
  static values = {
    // Core glass configuration
    enableGlass: { type: Boolean, default: true },
    glassType: { type: String, default: "rounded" }, // "rounded", "circle", "pill"
    borderRadius: { type: Number, default: 20 },
    tintOpacity: { type: Number, default: 0.12 },
    
    // Parallax configuration
    parallaxSpeed: { type: Number, default: 1 },
    parallaxOffset: { type: Number, default: 0 },
    isParallaxElement: { type: Boolean, default: false },
    syncWithParallax: { type: Boolean, default: true },
    backgroundParallaxSpeed: { type: Number, default: -2 },
    
    // Component-specific configuration
    componentType: { type: String, default: "nav" }, // "nav", "sidebar", "button", "card"
    cornerRounding: { type: String, default: "all" }, // "all", "right", "left", "top", "bottom"
    
    // Navigation-specific
    navItems: { type: Array, default: [] }
  }

  connect() {
    console.log('[GlassController] Connected:', this.element.className)
    this.isConnected = true
    this.glassContainer = undefined
    this.originalContent = undefined
    
    // Validate glass can be initialized
    if (!validateLiquidGlass(this.element)) {
      console.warn('[GlassController] Glass validation failed, using CSS fallback')
      this.setupFallback()
      return
    }

    if (this.enableGlassValue) {
      this.initializeGlass()
    }
  }

  disconnect() {
    console.log('[GlassController] Disconnecting')
    this.isConnected = false
    this.cleanupGlass()
  }

  initializeGlass() {
    if (!this.enableGlassValue) return
    
    try {
      // Store original content
      this.originalContent = this.element.innerHTML
      
      // Get navigation items if this is a nav component
      const navItems = this.getNavItems()
      
      // Prepare container options
      const containerOptions = this.getContainerOptions()
      
      // Prepare render options  
      const renderOptions = this.getRenderOptions()
      
      // Choose appropriate render function based on component type
      this.glassContainer = this.renderGlassComponent(navItems, containerOptions, renderOptions)
      
      // Apply post-render customizations
      this.postRenderSetup()
      
      console.log('[GlassController] Glass initialized successfully')
    } catch (error) {
      console.error('[GlassController] Error initializing glass:', error)
      this.setupFallback()
    }
  }

  getNavItems() {
    // Try to get nav items from data attribute
    const navItemsData = this.data.get('nav-items') || this.element.dataset.navItems
    if (!navItemsData) return []
    
    try {
      const rawNavItems = JSON.parse(navItemsData)
      
      // Transform items to include click handlers
      return rawNavItems.map(item => ({
        ...item,
        text: item.text || "",
        onClick: () => this.handleNavClick(item)
      }))
    } catch (error) {
      console.error('[GlassController] Failed to parse nav items:', error)
      return []
    }
  }

  getContainerOptions() {
    const options = {
      type: this.glassTypeValue,
      borderRadius: this.borderRadiusValue,
      tintOpacity: this.tintOpacityValue,
      parallaxSpeed: this.parallaxSpeedValue,
      parallaxOffset: this.parallaxOffsetValue,
      isParallaxElement: this.isParallaxElementValue,
      syncWithParallax: this.syncWithParallaxValue,
      backgroundParallaxSpeed: this.backgroundParallaxSpeedValue
    }

    // Apply corner rounding configuration
    if (this.cornerRoundingValue !== "all") {
      options.roundedCorners = this.getRoundedCorners()
    }

    return options
  }

  getRoundedCorners() {
    const rounding = this.cornerRoundingValue
    const roundedCorners = {
      topLeft: true,
      topRight: true,
      bottomLeft: true,
      bottomRight: true
    }

    switch (rounding) {
      case "right": {
        roundedCorners.topLeft = false
        roundedCorners.bottomLeft = false
        break
      }
      case "left": {
        roundedCorners.topRight = false
        roundedCorners.bottomRight = false
        break
      }
      case "top": {
        roundedCorners.bottomLeft = false
        roundedCorners.bottomRight = false
        break
      }
      case "bottom": {
        roundedCorners.topLeft = false
        roundedCorners.topRight = false
        break
      }
    }

    return roundedCorners
  }

  getRenderOptions() {
    return {
      preserveOriginalHTML: true,
      originalContent: this.originalContent,
      componentType: this.componentTypeValue
    }
  }

  renderGlassComponent(navItems, containerOptions, renderOptions) {
    const componentType = this.componentTypeValue
    const cornerRounding = this.cornerRoundingValue

    // Choose render function based on component type and corner rounding
    if (componentType === "sidebar" && cornerRounding === "right") {
      return renderLiquidGlassSidebarRightRounded(this.element, navItems, containerOptions, renderOptions)
    } else if (componentType === "nav" || componentType === "sidebar") {
      return renderLiquidGlassNav(this.element, navItems, containerOptions, renderOptions)
    } else {
      // For other component types, use basic nav renderer
      return renderLiquidGlassNav(this.element, navItems, containerOptions, renderOptions)
    }
  }

  postRenderSetup() {
    // Mark current page items as disabled if this is a navigation component
    if (this.componentTypeValue === "nav" || this.componentTypeValue === "sidebar") {
      this.markCurrentPageItems()
    }
    
    // Apply any custom post-render logic (can be overridden by subclasses)
    this.customPostRenderSetup()
  }

  markCurrentPageItems() {
    const currentPath = globalThis.location.pathname
    const buttons = this.element.querySelectorAll('.glass-button')
    
    for (const button of buttons) {
      if (button.dataset.path === currentPath) {
        button.classList.add('sidebar-disabled', 'sidebar-default-cursor')
        button.setAttribute('aria-disabled', 'true')
        button.setAttribute('tabindex', '-1')
      } else {
        button.classList.remove('sidebar-disabled', 'sidebar-default-cursor')
        button.removeAttribute('aria-disabled')
        button.removeAttribute('tabindex')
      }
    }
  }

  handleNavClick(item) {
    // Check if this is the current page
    const currentPath = globalThis.location.pathname
    const isCurrentPage = currentPath === item.path
    
    if (isCurrentPage) {
      // Show shake animation
      this.shakeButton(item.path)
    } else {
      // Navigate using Turbo or form submission
      this.navigate(item)
    }
  }

  shakeButton(path) {
    const buttons = this.element.querySelectorAll('.glass-button')
    for (const button of buttons) {
      if (button.dataset.path === path) {
        button.classList.add('sidebar-not-allowed-shake')
        setTimeout(() => {
          button.classList.remove('sidebar-not-allowed-shake')
        }, 750)
        break
      }
    }
  }

  navigate(item) {
    if (item.method === 'post') {
      // Handle POST requests (like logout)
      const form = document.createElement('form')
      form.method = 'POST'
      form.action = item.path
      
      // Add CSRF token
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
      if (csrfToken) {
        const csrfInput = document.createElement('input')
        csrfInput.type = 'hidden'
        csrfInput.name = 'authenticity_token'
        csrfInput.value = csrfToken
        form.append(csrfInput)
      }
      
      document.body.append(form)
      form.submit()
      form.remove()
    } else {
      // Regular GET navigation using Turbo
      Turbo.visit(item.path)
    }
  }

  cleanupGlass() {
    try {
      if (this.glassContainer && typeof this.glassContainer.destroy === 'function') {
        this.glassContainer.destroy()
      }
      
      // Restore original content
      if (this.originalContent && this.element) {
        this.restoreOriginalContent()
      }
    } catch (error) {
      console.error('[GlassController] Error cleaning up glass:', error)
    }
  }

  restoreOriginalContent() {
    // Show original content again
    const existingContent = this.element.querySelector('.sidebar-contents, .nav-contents, .card-contents')
    if (existingContent) {
      existingContent.style.display = ''
      existingContent.style.opacity = '1'
      existingContent.style.transition = ''
      existingContent.style.position = ''
      existingContent.style.zIndex = ''
    }
    
    // Remove glass container
    const glassElement = this.element.querySelector('.glass-container')
    if (glassElement) {
      glassElement.remove()
    }
    
    // Clean up references
    delete this.element._liquidGlassInstance
    delete this.element._originalHTML
  }

  setupFallback() {
    // Basic CSS glass effect fallback
    if (this.element) {
      this.element.style.backgroundColor = 'rgba(255, 255, 255, 0.1)'
      this.element.style.backdropFilter = 'blur(10px)'
      this.element.style.border = '1px solid rgba(255, 255, 255, 0.2)'
    }
  }

  // Method to be overridden by subclasses for custom behavior
  customPostRenderSetup() {
    // Override this in subclasses for component-specific setup
  }

  // Value change handlers
  enableGlassValueChanged() {
    if (!this.isConnected) return
    
    if (this.enableGlassValue && !this.glassContainer) {
      this.initializeGlass()
    } else if (!this.enableGlassValue && this.glassContainer) {
      this.cleanupGlass()
    }
  }

  // Refresh glass when configuration changes
  refreshGlass() {
    if (!this.isConnected || !this.glassContainer) return
    this.cleanupGlass()
    this.initializeGlass()
  }

  borderRadiusValueChanged() {
    this.refreshGlass()
  }

  tintOpacityValueChanged() {
    this.refreshGlass()
  }

  glassTypeValueChanged() {
    this.refreshGlass()
  }
}
