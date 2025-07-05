import GlassController from "./glass_controller.js"
import StimulusReflex from "stimulus_reflex"

/**
 * Drawer Controller - extends GlassController for drawer/modal components
 */
export default class extends GlassController {
  static values = {
    ...GlassController.values,
    // Override defaults for drawer
    componentType: { type: String, default: "drawer" },
    cornerRounding: { type: String, default: "top" },
    borderRadius: { type: Number, default: 20 },
    tintOpacity: { type: Number, default: 0.1 },
    
    // Drawer-specific values
    expanded: { type: Boolean, default: false },
    drawerId: { type: String, default: "main" },
    height: { type: Number, default: 60 },
    expandedHeight: { type: Number, default: 600 }
  }

  static targets = ["drawer", "overlay", "content", "icon"]

  connect() {
    console.log('[GlassDrawerController] Connected')
    console.log('[GlassDrawerController] Element:', this.element)
    console.log('[GlassDrawerController] Enable glass:', this.enableGlassValue)
    console.log('[GlassDrawerController] Component type:', this.componentTypeValue)
    super.connect()
    
    // Register with StimulusReflex
    this.registerStimulusReflex()
    
    // Bind event handlers
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundHandleKeydown)
    document.addEventListener("drawer:toggle", this.handleDrawerEvent.bind(this))
    
    // Set initial height based on expanded state
    this.updateDrawerHeight()
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleKeydown)
    document.removeEventListener("drawer:toggle", this.handleDrawerEvent)
    super.disconnect()
  }

  // Override to disable navigation for drawers
  getNavItems() {
    // Drawers don't typically have nav items like sidebars
    return []
  }

  // Override to handle drawer-specific click behavior
  handleNavClick(item) {
    // Custom drawer click behavior
    console.log('[GlassDrawerController] Drawer content clicked:', item)
    
    // Emit custom event for drawer interactions
    this.element.dispatchEvent(new CustomEvent('drawer:content-click', {
      detail: { item },
      bubbles: true
    }))
  }

  customPostRenderSetup() {
    console.log('[GlassDrawerController] Custom post-render setup')
    
    // Apply glass effect to drawer background
    const drawer = this.element.querySelector('.drawer')
    if (drawer) {
      // Enhanced glass appearance for drawer
      drawer.style.background = `rgba(255, 255, 255, ${this.tintOpacityValue})`
      drawer.style.backdropFilter = 'blur(15px)'
      drawer.style.border = '1px solid rgba(255, 255, 255, 0.2)'
      
      // Add subtle hover effect to toggle button
      const toggleButton = drawer.querySelector('.drawer-toggle')
      if (toggleButton) {
        toggleButton.addEventListener('mouseenter', () => {
          toggleButton.style.transform = 'scale(1.05)'
        })
        toggleButton.addEventListener('mouseleave', () => {
          toggleButton.style.transform = 'scale(1)'
        })
      }
    }
  }

  // StimulusReflex integration
  beforeReflex() {
    // Called before reflex actions
    console.log('[GlassDrawerController] Before reflex')
  }

  afterReflex() {
    // Called after reflex actions
    console.log('[GlassDrawerController] After reflex')
    this.updateDrawerHeight()
  }

  // Drawer-specific methods
  handleDrawerEvent(event) {
    if (event.detail.open) {
      this.open()
    }
    if (event.detail.close) {
      this.close()
    }
  }

  handleKeydown(event) {
    if (event.key === "Escape" && this.expandedValue) {
      this.close()
    }
  }

  /**
   * Toggle drawer state via StimulusReflex
   */
  toggle(event) {
    event?.preventDefault()
    
    // Use StimulusReflex to persist state on server
    this.stimulate("DrawerReflex#toggle", this.element, {
      drawer_id: this.drawerIdValue
    })
  }

  /**
   * Open drawer (client-side only)
   */
  open() {
    this.expandedValue = true
    this.updateDrawerHeight()
    this.updateAriaExpanded()
    
    // Emit event
    this.element.dispatchEvent(new CustomEvent('drawer:opened', {
      detail: { drawerId: this.drawerIdValue },
      bubbles: true
    }))
  }

  /**
   * Close drawer (client-side only)
   */
  close() {
    this.expandedValue = false
    this.updateDrawerHeight()
    this.updateAriaExpanded()
    
    // Emit event
    this.element.dispatchEvent(new CustomEvent('drawer:closed', {
      detail: { drawerId: this.drawerIdValue },
      bubbles: true
    }))
  }

  /**
   * Update drawer height based on expanded state
   */
  updateDrawerHeight() {
    const drawer = this.element.querySelector('.drawer')
    const content = this.element.querySelector('.drawer-contents')
    
    if (drawer && content) {
      if (this.expandedValue) {
        drawer.style.height = `${this.expandedHeightValue}px`
        drawer.classList.add('drawer-expanded')
        content.style.height = `${this.expandedHeightValue - this.heightValue}px`
      } else {
        drawer.style.height = `${this.heightValue}px`
        drawer.classList.remove('drawer-expanded')
        content.style.height = '0px'
      }
    }
    
    // Update glass container size if it exists
    if (this.glassContainer) {
      this.refreshGlass()
    }
  }

  /**
   * Update ARIA expanded attribute
   */
  updateAriaExpanded() {
    const toggleButton = this.element.querySelector('.drawer-toggle')
    if (toggleButton) {
      toggleButton.setAttribute('aria-expanded', this.expandedValue.toString())
    }
  }

  /**
   * Rotate toggle icon based on state
   */
  updateToggleIcon() {
    const icon = this.element.querySelector('.drawer-icons')
    if (icon) {
      if (this.expandedValue) {
        icon.style.transform = 'rotate(180deg)'
        icon.classList.add('rotated')
      } else {
        icon.style.transform = 'rotate(0deg)'
        icon.classList.remove('rotated')
      }
    }
  }

  // Value change handlers
  expandedValueChanged() {
    console.log('[GlassDrawerController] Expanded state changed:', this.expandedValue)
    this.updateDrawerHeight()
    this.updateAriaExpanded()
    this.updateToggleIcon()
  }

  heightValueChanged() {
    this.updateDrawerHeight()
  }

  expandedHeightValueChanged() {
    this.updateDrawerHeight()
  }

  // StimulusReflex registration - called by connect()
  registerStimulusReflex() {
    if (StimulusReflex !== undefined && typeof StimulusReflex.register === 'function') {
      StimulusReflex.register(this)
    }
  }
}
