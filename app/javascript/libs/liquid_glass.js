import { Container } from "./container.js"
import { Button } from "./button.js"

/**
 * Render a Liquid Glass navigation bar or sidebar into a given element.
 * @param {HTMLElement} element - The container element to render into.
 * @param {Array<{text: string, path: string, onClick?: function, buttonOptions?: object}>} navItems - Navigation items to render. Each item can have a custom onClick or buttonOptions.
 * @param {Object} [containerOptions] - Optional container options (borderRadius, tintOpacity, etc).
 * @param {Object} [renderOptions] - Rendering options
 * @param {boolean} [renderOptions.preserveOriginalHTML] - Whether to keep original HTML visible during load
 * @param {string} [renderOptions.originalContent] - Original HTML content to restore on cleanup
 * @param {string} [renderOptions.componentType] - Type of component being rendered
 * 
 * Container Types Available:
 * - Container.createSidebarContainer(options) - For sidebars (no parallax)
 * - Container.createParallaxContainer(speed, options) - For parallax elements  
 * - Container.createFixedContainer(options) - For fixed position elements
 * - new Container(options) - For custom configurations
 */
export function renderLiquidGlassNav(element, navItems, containerOptions = {}, renderOptions = {}) {
  if (!element) throw new Error("No container element provided")
  
  // Prevent multiple initializations of the same element
  if (element._liquidGlassInstance) {
    console.warn('Liquid glass already initialized on this element, skipping')
    return element._liquidGlassInstance
  }
  
  try {
    // Save the original HTML for fallback or restoration
    const originalHTML = renderOptions.originalContent || element.innerHTML
    
    // If preserveOriginalHTML is true, don't clear content initially
    if (!renderOptions.preserveOriginalHTML) {
      element.innerHTML = ""
    }
    
    const glassContainer = Container.createSidebarContainer({
      type: "rounded",
      borderRadius: 0,
      tintOpacity: 0.12,
      ...containerOptions
    })
    
    glassContainer.element.style.flexDirection = "column"
    glassContainer.element.style.alignItems = "stretch"
    glassContainer.element.style.width = "100%"
    glassContainer.element.style.height = "100%"

    // If preserving original HTML, position glass container appropriately
    if (renderOptions.preserveOriginalHTML) {
      glassContainer.element.style.position = 'absolute'
      glassContainer.element.style.top = '0'
      glassContainer.element.style.left = '0'
      glassContainer.element.style.zIndex = '1'
      
      // Make sure existing content is above glass
      const existingContent = element.querySelector('.sidebar-contents, .nav-contents, .card-contents, .button-contents')
      if (existingContent) {
        existingContent.style.position = 'relative'
        existingContent.style.zIndex = '2'
      }
    }

    for (const item of navItems) {
      // Skip items without SVG for nav components
      if (!item.svg && (renderOptions.componentType === 'nav' || renderOptions.componentType === 'sidebar')) {
        console.error(`Nav item missing required SVG content:`, item)
        continue
      }
      
      console.log('Processing nav item:', item.text, 'icon:', item.icon, 'path:', item.path, 'has SVG:', !!item.svg)
      
      const button = new Button({
        text: item.text || "", // Use provided text or empty
        size: 18,
        type: "pill",
        onClick: item.onClick || (() => { globalThis.location.href = item.path }),
        iconHTML: item.svg || "",
        ...(item.buttonOptions || {})
      })
      
      // Add data-path for navigation
      if (item.path) {
        button.element.dataset.path = item.path
      }
      
      // If preserving original HTML, hide glass buttons initially
      if (renderOptions.preserveOriginalHTML) {
        button.element.style.opacity = '0'
        button.element.style.pointerEvents = 'none'
      }
      
      console.log('Created button with text:', button.text, 'iconHTML present:', !!item.svg)
      glassContainer.addChild(button)
    }
    
    if (renderOptions.preserveOriginalHTML) {
      // Insert glass container at the beginning so it's behind existing content
      element.insertBefore(glassContainer.element, element.firstChild)
      
      // Set up transition after glass effect is ready
      setTimeout(() => {
        const existingContent = element.querySelector('.sidebar-contents, .nav-contents, .card-contents, .button-contents')
        const glassButtons = element.querySelectorAll('.glass-button')
        
        // Start transition
        if (existingContent) {
          existingContent.style.transition = 'opacity 300ms ease-out'
          existingContent.style.opacity = '0'
        }
        
        glassButtons.forEach(button => {
          button.style.transition = 'opacity 300ms ease-in'
          button.style.opacity = '1'
          button.style.pointerEvents = 'auto'
        })
        
        // After transition, hide original content completely
        setTimeout(() => {
          if (existingContent) {
            existingContent.style.display = 'none'
          }
        }, 300)
      }, 100) // Small delay to ensure glass effect is ready
    } else {
      element.append(glassContainer.element)
    }
    
    // Store reference on DOM element for cleanup
    element._liquidGlassInstance = glassContainer
    element._originalHTML = originalHTML
    
    return glassContainer
  } catch (error) {
    console.error('Error rendering liquid glass nav:', error)
    // If preserveOriginalHTML was true, we don't need to restore since content is still there
    if (!renderOptions.preserveOriginalHTML) {
      element.innerHTML = renderOptions.originalContent || originalHTML
    }
    // Return null on error, controller will handle graceful fallback
    return null
  }
}

/**
 * Validate that liquid glass can be initialized safely
 * @param {HTMLElement} element - Element to test
 * @returns {boolean} - Whether initialization would succeed
 */
export function validateLiquidGlass(element) {
  try {
    // Check basic requirements
    if (!element || !element.isConnected) {
      return false
    }
    
    // Check WebGL support
    const canvas = document.createElement('canvas')
    const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl')
    if (!gl) {
      console.warn('WebGL not supported, will use CSS fallback')
      return true // Still valid, just with fallback
    }
    
    // Check html2canvas availability
    if (typeof html2canvas === 'undefined') {
      console.warn('html2canvas not available')
      return false
    }
    
    return true
  } catch (error) {
    console.error('Liquid glass validation failed:', error)
    return false
  }
}

/**
 * Create a parallax-aware liquid glass container for content with parallax effects
 * @param {HTMLElement} element - The container element
 * @param {number} parallaxSpeed - Parallax speed (0.5 = half speed, 1.0 = normal, 2.0 = double speed)
 * @param {Object} [options] - Additional container options
 */
export function createParallaxGlassContainer(element, parallaxSpeed = 0.5, options = {}) {
  if (!element) throw new Error("No container element provided")
  
  const glassContainer = Container.createParallaxContainer(parallaxSpeed, {
    type: "rounded",
    borderRadius: 10,
    tintOpacity: 0.15,
    ...options
  })
  
  element.innerHTML = ""
  element.appendChild(glassContainer.element)
  
  return glassContainer
}

/**
 * Create a liquid glass container for fixed position elements
 * @param {HTMLElement} element - The container element
 * @param {Object} [options] - Container options
 * @param {number} [options.backgroundParallaxSpeed=0.5] - Speed of background parallax elements to sync with
 */
export function createFixedGlassContainer(element, options = {}) {
  if (!element) throw new Error("No container element provided")
  
  const glassContainer = Container.createFixedContainer({
    type: "rounded", 
    borderRadius: 10,
    tintOpacity: 0.1,
    ...options
  })
  
  element.innerHTML = ""
  element.appendChild(glassContainer.element)
  
  return glassContainer
}

/**
 * Render a Liquid Glass sidebar with only right corners rounded (for left-edge sidebars)
 * @param {HTMLElement} element - The container element to render into.
 * @param {Array} navItems - Navigation items to render
 * @param {Object} [containerOptions] - Optional container options
 * @param {Object} [renderOptions] - Rendering options
 * @param {boolean} [renderOptions.preserveOriginalHTML] - Whether to keep original HTML visible during load
 * @param {string} [renderOptions.originalContent] - Original HTML content to restore on cleanup
 */
export function renderLiquidGlassSidebarRightRounded(element, navItems, containerOptions = {}, renderOptions = {}) {
  if (!element) throw new Error("No container element provided")
  
  // Prevent multiple initializations
  if (element._liquidGlassInstance) {
    console.warn('Liquid glass already initialized on this element, skipping')
    return element._liquidGlassInstance
  }
  
  try {
    // Save the original HTML for fallback or restoration
    const originalHTML = renderOptions.originalContent || element.innerHTML
    
    // If preserveOriginalHTML is true, create glass container without clearing content initially
    if (!renderOptions.preserveOriginalHTML) {
      element.innerHTML = ""
    }
    
    const glassContainer = Container.createSidebarContainerRightRounded({
      type: "rounded",
      borderRadius: 0,
      tintOpacity: 0.12,
      ...containerOptions
    })
    
    // Same setup as regular sidebar...
    glassContainer.element.style.flexDirection = "column"
    glassContainer.element.style.alignItems = "stretch"
    glassContainer.element.style.width = "100%"
    glassContainer.element.style.height = "100%"

    // If preserving original HTML, position glass container behind existing content
    if (renderOptions.preserveOriginalHTML) {
      glassContainer.element.style.position = 'absolute'
      glassContainer.element.style.top = '0'
      glassContainer.element.style.left = '0'
      glassContainer.element.style.zIndex = '1'
      
      // Make sure existing content is above glass
      const existingContent = element.querySelector('.sidebar-contents')
      if (existingContent) {
        existingContent.style.position = 'relative'
        existingContent.style.zIndex = '2'
      }
    }

    // Add navigation items (same as regular renderLiquidGlassNav)
    for (const item of navItems) {
      // Require SVG content to be present
      if (!item.svg) {
        console.error(`Nav item missing required SVG content:`, item)
        continue // Skip items without SVG content
      }
      
      const button = new Button({
        iconHTML: item.svg,
        text: "", // Icons only for sidebar
        size: 18, // Add the missing size parameter
        type: "pill",
        onClick: item.onClick || (() => { globalThis.location.href = item.path }),
        path: item.path,
        label: item.label,
        method: item.method,
        ...(item.buttonOptions || {})
      })
      // Add data-path for current-page detection
      button.element.dataset.path = item.path
      
      // If preserving original HTML, hide glass buttons initially
      if (renderOptions.preserveOriginalHTML) {
        button.element.style.opacity = '0'
        button.element.style.pointerEvents = 'none'
      }
      
      glassContainer.addChild(button)
    }

    if (renderOptions.preserveOriginalHTML) {
      // Insert glass container at the beginning so it's behind existing content
      element.insertBefore(glassContainer.element, element.firstChild)
      
      // After a short delay, fade in glass buttons and fade out original content
      setTimeout(() => {
        const existingContent = element.querySelector('.sidebar-contents')
        const glassButtons = element.querySelectorAll('.glass-button')
        
        // Start transition
        if (existingContent) {
          existingContent.style.transition = 'opacity 300ms ease-out'
          existingContent.style.opacity = '0'
        }
        
        glassButtons.forEach(button => {
          button.style.transition = 'opacity 300ms ease-in'
          button.style.opacity = '1'
          button.style.pointerEvents = 'auto'
        })
        
        // After transition, hide original content completely
        setTimeout(() => {
          if (existingContent) {
            existingContent.style.display = 'none'
          }
        }, 300)
      }, 100) // Small delay to ensure glass effect is ready
    } else {
      element.appendChild(glassContainer.element)
    }
    
    element._liquidGlassInstance = glassContainer
    element._originalHTML = originalHTML
    
    return glassContainer
    
  } catch (error) {
    console.error('Error creating liquid glass sidebar:', error)
    // If preserveOriginalHTML was true, we don't need to restore since content is still there
    if (!renderOptions.preserveOriginalHTML) {
      element.innerHTML = renderOptions.originalContent || originalHTML
    }
    throw error
  }
}
