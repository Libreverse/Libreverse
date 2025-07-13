import { Controller } from "@hotwired/stimulus"
import { renderLiquidGlassSidebarRightRounded } from "../libs/liquid_glass.js"
import { Turbo } from "@hotwired/turbo-rails"

# SidebarController with Liquid Glass Integration
# -----------------------------------------------
# Provides liquid glass effects for sidebar navigation.
# Maintains WebGL glass rendering with proper cleanup and performance optimization.

export default class extends Controller
  # Define values that can be fed via data attributes
  @values = {
    # Liquid glass configuration
    enableGlass: { type: Boolean, default: true },
    borderRadius: { type: Number, default: 20 },
    tintOpacity: { type: Number, default: 0.12 },
    glassType: { type: String, default: "rounded" },
    # Parallax configuration
    parallaxSpeed: { type: Number, default: 1 },
    parallaxOffset: { type: Number, default: 0 },
    isParallaxElement: { type: Boolean, default: false },
    # Background parallax compensation
    syncWithParallax: { type: Boolean, default: true },
    backgroundParallaxSpeed: { type: Number, default: -2 },
  }

  # Extra method to check StimulusReflex registration
  initialize: ->
    console.log "[SidebarController] initialized", @element
    @glassContainer = undefined
    @originalNavContent = undefined

  connect: ->
    console.log "[SidebarController] connected"

    # Listen for fallback events on the sidebar
    @element.addEventListener "glass:fallbackActivated", @handleSidebarFallback.bind(@)

    # Initialize liquid glass effect if enabled
    # Use setTimeout to avoid conflicts during startup
    setTimeout =>
      if @enableGlassValue and not @glassContainer
        @initializeLiquidGlass()
    , 100

  handleSidebarFallback: ->
    console.log "[SidebarController] Sidebar glass fallback activated"

    # Ensure sidebar navigation remains visible and functional
    nav = @element.querySelector("nav") or @element
    if nav
      nav.style.opacity = "1"
      nav.style.visibility = "visible"

      # Apply emergency navigation styling
      nav.style.background = "linear-gradient(135deg, rgba(255, 255, 255, 0.1) 0%, rgba(255, 255, 255, 0.05) 100%)"
      nav.style.borderRadius = "12px"
      nav.style.padding = "16px"
      nav.style.margin = "8px"

      # Ensure nav items are visible
      navItems = nav.querySelectorAll('.nav-item, a, button')
      navItems.forEach (item) =>
        item.style.color = "rgba(255, 255, 255, 0.9)"
        item.style.opacity = "1"
        item.style.visibility = "visible"

  disconnect: ->
    # Clean up liquid glass resources
    @cleanupLiquidGlass()

  initializeLiquidGlass: ->
    # Find the nav element
    nav = @element.querySelector("nav") or @element

    # Store original HTML before liquid glass transformation
    @originalNavContent = nav.innerHTML

    # Get nav items from the data attribute (from Rails template) - REQUIRED
    navItemsData = nav.dataset.navItems
    unless navItemsData
      throw new Error("nav-items data attribute is required for liquid glass sidebar")

    try
      rawNavItems = JSON.parse(navItemsData)
    catch error
      throw new Error("Failed to parse nav-items data: #{error.message}")

    console.log "Raw nav items from template:", rawNavItems

    # Transform the Rails data structure to match our expected format
    navItems = rawNavItems.map (item) =>
      unless item.icon
        throw new Error("Nav item missing required icon: #{JSON.stringify(item)}")

      {
        text: "", # No text labels - icons only
        path: item.path,
        label: item.label, # Keep for accessibility
        icon: item.icon, # This will be the icon name like 'dashboard', 'settings', etc.
        svg: item.svg, # Preserve the SVG content from the template!
        method: item.method,
        # Add custom onClick handler for Turbo navigation
        onClick: => @handleNavItemClick(item),
      }

    console.log "Final nav items for glass rendering:", navItems

    # Container options
    containerOptions = {
      type: @glassTypeValue,
      borderRadius: @borderRadiusValue,
      tintOpacity: @tintOpacityValue,
      # Pass through parallax configuration
      parallaxSpeed: @parallaxSpeedValue,
      parallaxOffset: @parallaxOffsetValue,
      isParallaxElement: @isParallaxElementValue,
      # Pass through background parallax compensation
      syncWithParallax: @syncWithParallaxValue,
      backgroundParallaxSpeed: @backgroundParallaxSpeedValue,
    }

    # Initialize liquid glass with preservation of original HTML
    @glassContainer = renderLiquidGlassSidebarRightRounded(
      nav,
      navItems,
      containerOptions,
      {
        preserveOriginalHTML: true,
        originalContent: @originalNavContent,
      }
    )

    console.log "[SidebarController] Liquid glass initialized with", navItems.length, "items"

    # Mark element as having active glass effect
    @element.setAttribute("data-glass-active", "true")

    # After rendering, mark the current page button as disabled but keep pointer events
    currentPath = globalThis.location.pathname
    buttons = @element.querySelectorAll ".glass-button"
    for button in buttons
      if button.dataset.path is currentPath
        button.classList.add "sidebar-disabled", "sidebar-default-cursor"
        button.setAttribute "aria-disabled", "true"
        button.setAttribute "tabindex", "-1"
        # Don't disable pointer-events - we need clicks for shake animation
      else
        button.classList.remove "sidebar-disabled", "sidebar-default-cursor"
        button.removeAttribute "aria-disabled"
        button.removeAttribute "tabindex"

  cleanupLiquidGlass: ->
    try
      # Remove glass active marker
      @element.removeAttribute("data-glass-active") if @element

      if @glassContainer and typeof @glassContainer.destroy is "function"
        @glassContainer.destroy()

      # Restore original content if we have it
      if @originalNavContent and @element
        nav = @element.querySelector("nav") or @element

        # Show original content again
        existingContent = nav.querySelector ".sidebar-contents"
        if existingContent
          existingContent.style.display = ""
          existingContent.style.opacity = "1"
          existingContent.style.transition = ""
          existingContent.style.position = ""
          existingContent.style.zIndex = ""

        # Remove glass container
        glassElement = nav.querySelector ".glass-container"
        if glassElement
          glassElement.remove()

        # Clean up references
        delete nav._liquidGlassInstance
        delete nav._originalHTML
    catch error
      console.error "[SidebarController] Error cleaning up liquid glass:", error

  # Action to refresh the liquid glass effect
  refreshGlass: ->
    if @enableGlassValue
      @cleanupLiquidGlass()
      @initializeLiquidGlass()

  # Value change handlers
  enableGlassValueChanged: ->
    # Skip during initial connection to prevent multiple initializations
    return unless @isConnected

    if @enableGlassValue and not @glassContainer
      @initializeLiquidGlass()
    else if not @enableGlassValue and @glassContainer
      @cleanupLiquidGlass()

  borderRadiusValueChanged: ->
    # Skip during initial connection
    return unless @isConnected and @glassContainer
    @refreshGlass()

  tintOpacityValueChanged: ->
    # Skip during initial connection
    return unless @isConnected and @glassContainer
    @refreshGlass()

  glassTypeValueChanged: ->
    # Skip during initial connection
    return unless @isConnected and @glassContainer
    @refreshGlass()

  handleNavItemClick: (item) ->
    # Check if this is the current page
    currentPath = globalThis.location.pathname
    isCurrentPage = currentPath is item.path

    if isCurrentPage
      # Current page - show shake animation (find the button element)
      buttons = @element.querySelectorAll ".glass-button"
      for button in buttons
        # Find the button that corresponds to this item
        buttonPath = button.dataset.path
        if buttonPath is item.path
          button.classList.add "sidebar-not-allowed-shake"
          setTimeout =>
            button.classList.remove "sidebar-not-allowed-shake"
          , 750
          break # Found the button, no need to continue
    else
      # Navigate to new page
      if item.method is "post"
        # Handle POST requests (like logout) - create a form and submit it
        form = document.createElement "form"
        form.method = "POST"
        form.action = item.path

        # Add CSRF token
        csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")
        if csrfToken
          csrfInput = document.createElement "input"
          csrfInput.type = "hidden"
          csrfInput.name = "authenticity_token"
          csrfInput.value = csrfToken
          form.append csrfInput

        document.body.append form
        form.submit()
        form.remove()
      else
        # Regular GET navigation using Turbo
        Turbo.visit item.path
