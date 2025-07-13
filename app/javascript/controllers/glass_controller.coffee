import { Controller } from "@hotwired/stimulus"
import { useStore } from "stimulus-store"
import { themeStore, glassConfigStore, navigationStore } from "../stores"
import {
  renderLiquidGlassNav,
  renderLiquidGlassSidebarRightRounded,
  renderLiquidGlassDrawer,
  validateLiquidGlass,
  getGlassPerformanceStats,
  batchUpdateGlassComponents,
} from "../libs/liquid_glass.js"
import { glassConfigManager } from "../libs/glass_config_manager.js"
import { Turbo } from "@hotwired/turbo-rails"

###
Glass Controller with stimulus-store integration - can be extended by other controllers for liquid glass effects

Usage:
1. Add data-controller="glass" to any element
2. Configure with data-glass-*-value attributes
3. Optionally extend this controller for custom behavior
###
export default class extends Controller
  @stores = [themeStore, glassConfigStore, navigationStore]

  @values = {
    # Core glass configuration
    enableGlass: { type: Boolean, default: true },
    glassType: { type: String, default: "rounded" }, # "rounded", "circle", "pill"
    borderRadius: { type: Number, default: 20 },
    tintOpacity: { type: Number, default: 0.12 },

    # Parallax configuration
    parallaxSpeed: { type: Number, default: 1 },
    parallaxOffset: { type: Number, default: 0 },
    isParallaxElement: { type: Boolean, default: false },
    syncWithParallax: { type: Boolean, default: true },
    backgroundParallaxSpeed: { type: Number, default: -2 },

    # Component-specific configuration
    componentType: { type: String, default: "nav" }, # "nav", "sidebar", "button", "card"
    cornerRounding: { type: String, default: "all" }, # "all", "right", "left", "top", "bottom"

    # Navigation-specific
    navItems: { type: Array, default: [] },

    # Enable/disable overrides
    forceEnable: { type: Boolean, default: false },
    forceDisable: { type: Boolean, default: false },
  }

  connect: ->
    console.log "[GlassController] Connected:", @element.className

    # Set up stimulus-store
    useStore(@)

    @isConnected = true
    @glassContainer = undefined
    @originalContent = undefined

    # Listen for global glass config updates
    @setupGlassConfigListener()

    # Register with fallback monitor
    @registerWithFallbackMonitor()

    # Listen for canvas failure events from liquid glass
    @setupCanvasFailureListener()

    # Validate glass can be initialized
    unless @shouldEnableGlass()
      console.warn "[GlassController] Glass disabled, using CSS fallback"
      @setupFallback()
      return

    unless validateLiquidGlass(@element)
      console.warn "[GlassController] Glass validation failed, using CSS fallback"
      @setupFallback()
      return

    if @enableGlassValue
      @initializeGlass()

  setupCanvasFailureListener: ->
    # Listen for canvas failure events dispatched by liquid glass
    @element.addEventListener 'glass:fallbackActivated', (event) =>
      console.warn "[GlassController] Canvas failure detected:", event.detail.error
      @setupFallback() unless @fallbackActive

    # Listen for WebGL context loss events
    @element.addEventListener 'webglcontextlost', (event) =>
      console.warn "[GlassController] WebGL context lost"
      event.preventDefault()
      @setupFallback() unless @fallbackActive

  registerWithFallbackMonitor: ->
    if window.glassFallbackMonitor
      # Add observer to monitor fallback triggers
      @fallbackObserver = (reason) =>
        console.warn "[GlassController] Global fallback triggered: #{reason}"
        @setupFallback() unless @fallbackActive

      window.glassFallbackMonitor.addObserver(@fallbackObserver)

  disconnect: ->
    console.log "[GlassController] Disconnecting"
    @isConnected = false
    @cleanupGlassConfigListener()

    # Cancel any pending config updates
    glassConfigManager.cleanup(@element)

    # Unregister from fallback monitor
    if window.glassFallbackMonitor and @fallbackObserver
      window.glassFallbackMonitor.removeObserver(@fallbackObserver)

    # Clean up both glass and fallback states
    @cleanupGlass()
    @cleanupFallback()

  initializeGlass: ->
    return unless @enableGlassValue

    try
      # Store original content
      @originalContent = @element.innerHTML

      # Get navigation items if this is a nav component
      navItems = @getNavItems()

      # Prepare container options
      containerOptions = @getContainerOptions()

      # Prepare render options
      renderOptions = @getRenderOptions()

      # Choose appropriate render function based on component type
      @renderGlassComponent(navItems, containerOptions, renderOptions)
        .then (glassContainer) =>
          if glassContainer and glassContainer.element
            @glassContainer = glassContainer

            # Glass loaded successfully - activate glass mode
            @element.setAttribute("data-glass-active", "true")
            @element.removeAttribute("data-glass-loading")
            @element.classList.remove("glass-fallback")

            # Apply post-render customizations
            @postRenderSetup()

            console.log "[GlassController] Glass initialized successfully"
          else
            console.warn "[GlassController] Glass container creation failed, activating fallback"
            @setupFallback()
        .catch (error) =>
          console.error "[GlassController] Error initializing glass:", error
          @setupFallback()
    catch error
      console.error "[GlassController] Error initializing glass:", error
      @setupFallback()

  getNavItems: ->
    # Try to get nav items from data attribute
    navItemsData = @data.get("nav-items") or @element.dataset.navItems
    return [] unless navItemsData

    try
      rawNavItems = JSON.parse navItemsData

      # Transform items to include click handlers
      rawNavItems.map (item) =>
        {
          ...item,
          text: item.text or "",
          onClick: => @handleNavClick(item),
        }
    catch error
      console.error "[GlassController] Failed to parse nav items:", error
      []

  getContainerOptions: ->
    options = {
      type: @glassTypeValue,
      borderRadius: @borderRadiusValue,
      tintOpacity: @tintOpacityValue,
      parallaxSpeed: @parallaxSpeedValue,
      parallaxOffset: @parallaxOffsetValue,
      isParallaxElement: @isParallaxElementValue,
      syncWithParallax: @syncWithParallaxValue,
      backgroundParallaxSpeed: @backgroundParallaxSpeedValue,
    }

    # Apply corner rounding configuration
    if @cornerRoundingValue isnt "all"
      options.roundedCorners = @getRoundedCorners()

    options

  getRoundedCorners: ->
    rounding = @cornerRoundingValue
    roundedCorners = {
      topLeft: true,
      topRight: true,
      bottomLeft: true,
      bottomRight: true,
    }

    switch rounding
      when "right"
        roundedCorners.topLeft = false
        roundedCorners.bottomLeft = false
      when "left"
        roundedCorners.topRight = false
        roundedCorners.bottomRight = false
      when "top"
        roundedCorners.bottomLeft = false
        roundedCorners.bottomRight = false
      when "bottom"
        roundedCorners.topLeft = false
        roundedCorners.topRight = false

    roundedCorners

  getRenderOptions: ->
    {
      preserveOriginalHTML: true,
      originalContent: @originalContent,
      componentType: @componentTypeValue,
    }

  renderGlassComponent: (navItems, containerOptions, renderOptions) ->
    componentType = @componentTypeValue
    cornerRounding = @cornerRoundingValue

    # Choose render function based on component type and corner rounding
    if componentType is "drawer"
      renderLiquidGlassDrawer(
        @element,
        containerOptions,
        renderOptions,
      )
    else if componentType is "sidebar" and cornerRounding is "right"
      renderLiquidGlassSidebarRightRounded(
        @element,
        navItems,
        containerOptions,
        renderOptions,
      )
    else if componentType is "nav" or componentType is "sidebar"
      renderLiquidGlassNav(
        @element,
        navItems,
        containerOptions,
        renderOptions,
      )
    else
      # For other component types, use basic nav renderer
      renderLiquidGlassNav(
        @element,
        navItems,
        containerOptions,
        renderOptions,
      )

  postRenderSetup: ->
    # Mark current page items as disabled if this is a navigation component
    if @componentTypeValue is "nav" or @componentTypeValue is "sidebar"
      @markCurrentPageItems()

    # Apply any custom post-render logic (can be overridden by subclasses)
    @customPostRenderSetup()

  markCurrentPageItems: ->
    currentPath = globalThis.location.pathname
    buttons = @element.querySelectorAll ".glass-button"

    for button in buttons
      if button.dataset.path is currentPath
        button.classList.add "sidebar-disabled", "sidebar-default-cursor"
        button.setAttribute "aria-disabled", "true"
        button.setAttribute "tabindex", "-1"
      else
        button.classList.remove "sidebar-disabled", "sidebar-default-cursor"
        button.removeAttribute "aria-disabled"
        button.removeAttribute "tabindex"

  handleNavClick: (item) ->
    # Check if this is the current page
    currentPath = globalThis.location.pathname
    isCurrentPage = currentPath is item.path

    if isCurrentPage
      # Show shake animation
      @shakeButton item.path
    else
      # Navigate using Turbo or form submission
      @navigate item

  shakeButton: (path) ->
    buttons = @element.querySelectorAll ".glass-button"
    for button in buttons
      if button.dataset.path is path
        button.classList.add "sidebar-not-allowed-shake"
        setTimeout =>
          button.classList.remove "sidebar-not-allowed-shake"
        , 750
        break

  navigate: (item) ->
    if item.method is "post"
      # Handle POST requests (like logout)
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

  cleanupGlass: ->
    try
      if @glassContainer and typeof @glassContainer.destroy is "function"
        @glassContainer.destroy()

      # Restore original content
      if @originalContent and @element
        @restoreOriginalContent()
    catch error
      console.error "[GlassController] Error cleaning up glass:", error

  restoreOriginalContent: ->
    # Show original content again
    existingContent = @element.querySelector ".sidebar-contents, .nav-contents, .card-contents"
    if existingContent
      existingContent.style.display = ""
      existingContent.style.opacity = "1"
      existingContent.style.transition = ""
      existingContent.style.position = ""
      existingContent.style.zIndex = ""

    # Remove glass container
    glassElement = @element.querySelector ".glass-container"
    if glassElement
      glassElement.remove()

    # Clean up references
    delete @element._liquidGlassInstance
    delete @element._originalHTML

  setupFallback: ->
    return unless @element

    # Set fallback state - keeps default styling but with enhanced effects
    @element.setAttribute("data-glass-loading", "false")
    @element.removeAttribute("data-glass-active")

    # Add fallback class for enhanced CSS styling
    @element.classList.add("glass-fallback")

    # Enhanced fallback for sidebar specifically
    if @componentTypeValue is "sidebar"
      @setupSidebarFallback()
    else
      @setupGenericFallback()

    # Add retry button if not already present
    @addRetryButton() unless @element.querySelector('.glass-retry-button')

    # Track fallback state
    @fallbackActive = true

    console.log "[GlassController] Enhanced CSS fallback activated for #{@componentTypeValue}"

  setupSidebarFallback: ->
    # Ensure sidebar contents are properly visible
    sidebarContents = @element.querySelector('.sidebar-contents')
    if sidebarContents
      sidebarContents.style.opacity = "1"
      sidebarContents.style.visibility = "visible"
      sidebarContents.style.zIndex = "2"
      sidebarContents.style.position = "relative"

    # Hide any glass containers that might be present
    glassContainers = @element.querySelectorAll('.glass-container')
    glassContainers.forEach (container) =>
      container.style.display = "none"

    # Ensure proper sidebar styling
    @element.style.opacity = "1"
    @element.style.visibility = "visible"

    # Add enhanced visual feedback
    @addSidebarFallbackIndicator()

  setupGenericFallback: ->
    # Basic fallback for non-sidebar components
    @element.style.opacity = "1"
    @element.style.visibility = "visible"

    # Hide glass containers
    glassContainers = @element.querySelectorAll('.glass-container')
    glassContainers.forEach (container) =>
      container.style.display = "none"

  addSidebarFallbackIndicator: ->
    return if @element.querySelector('.sidebar-fallback-indicator')

    indicator = document.createElement('div')
    indicator.className = 'sidebar-fallback-indicator'
    indicator.style.cssText = '''
      position: absolute;
      top: 4px;
      left: 4px;
      width: 6px;
      height: 6px;
      background: rgba(255, 165, 0, 0.8);
      border-radius: 50%;
      animation: pulse 2s infinite;
      z-index: 1000;
    '''

    @element.appendChild(indicator)

  retryGlassEffect: ->
    return unless @fallbackActive

    console.log "[GlassController] Retrying glass effect..."

    # Add retrying state
    @element.classList.add("glass-retrying")

    # Remove retry button temporarily
    retryButton = @element.querySelector('.glass-retry-button')
    retryButton?.remove()

    # Force cleanup of any existing WebGL contexts
    if window.optimizedWebGLContextManager
      window.optimizedWebGLContextManager.aggressiveCleanup()

    # Clear fallback state
    @fallbackActive = false
    @element.classList.remove("glass-fallback")

    # Set loading state
    @element.setAttribute("data-glass-loading", "true")

    # Wait a moment then retry
    setTimeout =>
      @element.classList.remove("glass-retrying")

      # Attempt to reinitialize glass
      try
        @initializeGlass()
      catch error
        console.error "[GlassController] Retry failed:", error
        # Restore fallback if retry fails
        @setupFallback()
    , 1500

  cleanupFallback: ->
    return unless @element

    # Remove fallback classes and indicators
    @element.classList.remove("glass-fallback", "glass-retrying")
    @element.removeAttribute("data-glass-loading")

    # Remove fallback indicators
    indicator = @element.querySelector('.sidebar-fallback-indicator')
    indicator?.remove()

    retryButton = @element.querySelector('.glass-retry-button')
    retryButton?.remove()

    @fallbackActive = false

  # Method to be overridden by subclasses for custom behavior
  customPostRenderSetup: ->
    # Override this in subclasses for component-specific setup
    console.log "[GlassController] Custom post-render setup"

  # Store integration methods

  # Check if glass should be enabled based on global and local settings
  shouldEnableGlass: ->
    # Force disable takes precedence
    return false if @forceDisableValue

    # Force enable overrides global setting
    return true if @forceEnableValue

    # Check if enabled by data attribute (backwards compatibility)
    return @enableGlassValue if @hasEnableGlassValue

    # Check global theme setting
    return @themeStoreValue?.glassEnabled ? true

  # Set up listener for glass config changes
  setupGlassConfigListener: ->
    @glassConfigListener = @handleGlassConfigChange.bind(@)
    document.addEventListener("glassConfig:updated", @glassConfigListener)

  # Clean up glass config listener
  cleanupGlassConfigListener: ->
    document.removeEventListener("glassConfig:updated", @glassConfigListener) if @glassConfigListener

  # Handle glass config changes
  handleGlassConfigChange: (event) ->
    return unless @isConnected and @glassContainer

    console.log "[GlassController] Updating glass config"

    # Get the new config
    newConfig = event.detail.config

    # Update the glass config store (this will trigger a re-render)
    @glassConfigStoreValue = { ...@glassConfigStoreValue, ...newConfig }

    # Re-initialize glass with new config
    @reinitializeGlass()

  # Store change handlers
  glassConfigStoreChanged: ->
    return unless @isConnected and @shouldEnableGlass()
    @reinitializeGlass()

  themeStoreChanged: ->
    currentlyEnabled = @glassContainer?
    shouldBeEnabled = @shouldEnableGlass()

    if currentlyEnabled and not shouldBeEnabled
      # Disable glass
      @cleanupGlass()
      @setupFallback()
    else if not currentlyEnabled and shouldBeEnabled
      # Enable glass
      @initializeGlass()

  # Re-initialize glass with current config
  reinitializeGlass: ->
    return unless @shouldEnableGlass()

    # Use debounced config manager for better performance
    glassConfigManager.scheduleUpdate(@element, =>
      # Clean up existing glass
      @cleanupGlass()
      # Re-initialize with current config
      @initializeGlass()
    )

  # Value change handlers - now use debounced updates
  enableGlassValueChanged: ->
    return unless @isConnected

    glassConfigManager.scheduleUpdate(@element, =>
      if @enableGlassValue and not @glassContainer
        @initializeGlass()
      else if not @enableGlassValue and @glassContainer
        @cleanupGlass()
    )

  # Optimized refresh glass with debouncing
  refreshGlass: ->
    return unless @isConnected and @glassContainer

    glassConfigManager.scheduleUpdate(@element, =>
      @cleanupGlass()
      @initializeGlass()
    )

  borderRadiusValueChanged: ->
    @refreshGlass()

  tintOpacityValueChanged: ->
    @refreshGlass()

  glassTypeValueChanged: ->
    @refreshGlass()

  # Performance monitoring method
  getPerformanceStats: ->
    getGlassPerformanceStats()
