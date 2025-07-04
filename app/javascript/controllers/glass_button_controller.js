import GlassController from "./glass_controller.js"

/**
 * Button Controller - extends GlassController for standalone button components
 */
export default class extends GlassController {
  static values = {
    ...GlassController.values,
    // Override defaults for buttons
    componentType: { type: String, default: "button" },
    cornerRounding: { type: String, default: "all" },
    borderRadius: { type: Number, default: 25 },
    glassType: { type: String, default: "pill" },
    tintOpacity: { type: Number, default: 0.15 },
    
    // Button-specific values
    buttonText: { type: String, default: "" },
    buttonIcon: { type: String, default: "" },
    buttonPath: { type: String, default: "" },
    buttonMethod: { type: String, default: "get" }
  }

  connect() {
    console.log('[ButtonController] Connected')
    super.connect()
  }

  // Override to create button-specific nav items
  getNavItems() {
    // Create a single nav item for this button
    return [{
      text: this.buttonTextValue,
      path: this.buttonPathValue,
      icon: this.buttonIconValue,
      method: this.buttonMethodValue,
      svg: this.extractSvgFromButton()
    }]
  }

  extractSvgFromButton() {
    // Try to extract SVG content from the button
    const svg = this.element.querySelector('svg')
    return svg ? svg.outerHTML : ''
  }

  // Override navigation handling for single buttons
  handleNavClick(item) {
    // Single button navigation
    if (item.path) {
      this.navigate(item)
    } else {
      // Emit custom event for button interactions
      this.element.dispatchEvent(new CustomEvent('button:click', {
        detail: { item },
        bubbles: true
      }))
    }
  }

  customPostRenderSetup() {
    // Button-specific logic
    console.log('[ButtonController] Custom post-render setup')
    
    // Add press effect for buttons
    const glassButtons = this.element.querySelectorAll('.glass-button')
    for (const button of glassButtons) {
      button.addEventListener('mousedown', () => {
        button.style.transform = 'scale(0.95)'
      })
      button.addEventListener('mouseup', () => {
        button.style.transform = 'scale(1)'
      })
      button.addEventListener('mouseleave', () => {
        button.style.transform = 'scale(1)'
      })
    }
  }
}
