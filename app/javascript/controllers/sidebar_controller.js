import { Controller } from "@hotwired/stimulus"
import { renderLiquidGlassSidebarRightRounded } from "../libs/liquid_glass.js"
import { Turbo } from "@hotwired/turbo-rails"

// SidebarController with Liquid Glass Integration
// -----------------------------------------------
// Provides liquid glass effects for sidebar navigation.
// Maintains WebGL glass rendering with proper cleanup and performance optimization.

export default class extends Controller {
  // Define values that can be fed via data attributes
  static values = {
    // Liquid glass configuration
    enableGlass: { type: Boolean, default: true },
    borderRadius: { type: Number, default: 20 },
    tintOpacity: { type: Number, default: 0.12 },
    glassType: { type: String, default: "rounded" },
    // Parallax configuration
    parallaxSpeed: { type: Number, default: 1 },
    parallaxOffset: { type: Number, default: 0 },
    isParallaxElement: { type: Boolean, default: false },
    // Background parallax compensation
    syncWithParallax: { type: Boolean, default: true },
    backgroundParallaxSpeed: { type: Number, default: -2 }
  }

  // Extra method to check StimulusReflex registration
  initialize() {
    console.log("[SidebarController] initialized", this.element)
    this.glassContainer = undefined
    this.originalNavContent = undefined
  }

  connect() {
    console.log("[SidebarController] connected")
    
    // Initialize liquid glass effect if enabled
    // Use setTimeout to avoid conflicts during startup
    setTimeout(() => {
      if (this.enableGlassValue && !this.glassContainer) {
        this.initializeLiquidGlass()
      }
    }, 100)
  }

  disconnect() {
    // Clean up liquid glass resources
    this.cleanupLiquidGlass()
  }

  initializeLiquidGlass() {
    // Find the nav element
    const nav = this.element.querySelector('nav') || this.element
    
    // Store original HTML before liquid glass transformation
    this.originalNavContent = nav.innerHTML
    
    // Get nav items from the data attribute (from Rails template) - REQUIRED
    const navItemsData = nav.dataset.navItems
    if (!navItemsData) {
      throw new Error('nav-items data attribute is required for liquid glass sidebar')
    }
    
    let rawNavItems
    try {
      rawNavItems = JSON.parse(navItemsData)
    } catch (error) {
      throw new Error(`Failed to parse nav-items data: ${error.message}`)
    }
    
    console.log('Raw nav items from template:', rawNavItems)
    
    // Transform the Rails data structure to match our expected format
    const navItems = rawNavItems.map(item => {
      if (!item.icon) {
        throw new Error(`Nav item missing required icon: ${JSON.stringify(item)}`)
      }
      
      return {
        text: "", // No text labels - icons only
        path: item.path,
        label: item.label, // Keep for accessibility
        icon: item.icon, // This will be the icon name like 'dashboard', 'settings', etc.
        svg: item.svg, // Preserve the SVG content from the template!
        method: item.method,
        // Add custom onClick handler for Turbo navigation
        onClick: () => this.handleNavItemClick(item)
      }
    })

    console.log('Final nav items for glass rendering:', navItems)

    // Container options
    const containerOptions = {
      type: this.glassTypeValue,
      borderRadius: this.borderRadiusValue,
      tintOpacity: this.tintOpacityValue,
      // Pass through parallax configuration
      parallaxSpeed: this.parallaxSpeedValue,
      parallaxOffset: this.parallaxOffsetValue,
      isParallaxElement: this.isParallaxElementValue,
      // Pass through background parallax compensation
      syncWithParallax: this.syncWithParallaxValue,
      backgroundParallaxSpeed: this.backgroundParallaxSpeedValue
    }

    // Initialize liquid glass
    this.glassContainer = renderLiquidGlassSidebarRightRounded(nav, navItems, containerOptions)
    
    console.log('[SidebarController] Liquid glass initialized with', navItems.length, 'items')

    // After rendering, mark the current page button as disabled but keep pointer events
    const currentPath = globalThis.location.pathname
    const buttons = this.element.querySelectorAll('.glass-button')
    for (const button of buttons) {
      if (button.dataset.path === currentPath) {
        button.classList.add('sidebar-disabled', 'sidebar-default-cursor')
        button.setAttribute('aria-disabled', 'true')
        button.setAttribute('tabindex', '-1')
        // Don't disable pointer-events - we need clicks for shake animation
      } else {
        button.classList.remove('sidebar-disabled', 'sidebar-default-cursor')
        button.removeAttribute('aria-disabled')
        button.removeAttribute('tabindex')
      }
    }
  }

  cleanupLiquidGlass() {
    try {
      if (this.glassContainer && typeof this.glassContainer.destroy === 'function') {
        this.glassContainer.destroy()
      }
      
      // Restore original content if we have it
      if (this.originalNavContent && this.element) {
        const nav = this.element.querySelector('nav') || this.element
        nav.innerHTML = this.originalNavContent
      }
    } catch (error) {
      console.error('[SidebarController] Error cleaning up liquid glass:', error)
    }
  }

  // Action to refresh the liquid glass effect
  refreshGlass() {
    if (this.enableGlassValue) {
      this.cleanupLiquidGlass()
      this.initializeLiquidGlass()
    }
  }

  // Value change handlers
  enableGlassValueChanged() {
    // Skip during initial connection to prevent multiple initializations
    if (!this.isConnected) return
    
    if (this.enableGlassValue && !this.glassContainer) {
      this.initializeLiquidGlass()
    } else if (!this.enableGlassValue && this.glassContainer) {
      this.cleanupLiquidGlass()
    }
  }

  borderRadiusValueChanged() {
    // Skip during initial connection
    if (!this.isConnected || !this.glassContainer) return
    this.refreshGlass()
  }

  tintOpacityValueChanged() {
    // Skip during initial connection
    if (!this.isConnected || !this.glassContainer) return
    this.refreshGlass()
  }

  glassTypeValueChanged() {
    // Skip during initial connection
    if (!this.isConnected || !this.glassContainer) return
    this.refreshGlass()
  }

  handleNavItemClick(item) {
    // Check if this is the current page
    const currentPath = globalThis.location.pathname
    const isCurrentPage = currentPath === item.path
    
    if (isCurrentPage) {
      // Current page - show shake animation (find the button element)
      const buttons = this.element.querySelectorAll('.glass-button')
      for (const button of buttons) {
        // Find the button that corresponds to this item
        const buttonPath = button.dataset.path
        if (buttonPath === item.path) {
          button.classList.add('sidebar-not-allowed-shake')
          setTimeout(() => {
            button.classList.remove('sidebar-not-allowed-shake')
          }, 750)
          break // Found the button, no need to continue
        }
      }
    } else {
      // Navigate to new page
      if (item.method === 'post') {
        // Handle POST requests (like logout) - create a form and submit it
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
  }
}
