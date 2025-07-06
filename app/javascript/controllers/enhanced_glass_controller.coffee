import { Controller } from "@hotwired/stimulus"
import { useStore } from "stimulus-store"
import { themeStore, glassConfigStore, navigationStore } from "../stores"
import {
  renderLiquidGlassNav,
  renderLiquidGlassSidebarRightRounded,
  renderLiquidGlassDrawer,
  validateLiquidGlass,
} from "../libs/liquid_glass.js"
import { Turbo } from "@hotwired/turbo-rails"

###
Enhanced Glass Controller with stimulus-store integration
Provides centralized glass effect management with shared state
###
export default class extends Controller
  @stores = [themeStore, glassConfigStore, navigationStore]

  @values = {
    # Component-specific configuration that can override global settings
    componentType: { type: String, default: "nav" },
    cornerRounding: { type: String, default: "all" },
    navItems: { type: Array, default: [] },
    # Enable/disable overrides
    forceEnable: { type: Boolean, default: false },
    forceDisable: { type: Boolean, default: false },
  }

  connect: ->
    console.log "[EnhancedGlassController] Connected:", @element.className
    
    # Set up stimulus-store
    useStore(@)
    
    @isConnected = true
    @glassContainer = undefined
    @originalContent = undefined

    # Listen for global glass config updates
    @setupGlassConfigListener()

    # Check if glass should be enabled
    unless @shouldEnableGlass()
      console.warn "[EnhancedGlassController] Glass disabled, using CSS fallback"
      @setupFallback()
      return

    # Validate glass can be initialized
    unless validateLiquidGlass(@element)
      console.warn "[EnhancedGlassController] Glass validation failed, using CSS fallback"
      @setupFallback()
      return

    @initializeGlass()

  disconnect: ->
    console.log "[EnhancedGlassController] Disconnecting"
    @isConnected = false
    @cleanupGlassConfigListener()
    @cleanupGlass()

  # Check if glass should be enabled based on global and local settings
  shouldEnableGlass: ->
    # Force disable takes precedence
    return false if @forceDisableValue
    
    # Force enable overrides global setting
    return true if @forceEnableValue
    
    # Check global theme setting
    return @themeStoreValue.glassEnabled

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

    console.log "[EnhancedGlassController] Updating glass config"
    
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

  initializeGlass: ->
    return unless @shouldEnableGlass()

    try
      # Store original content
      @originalContent = @element.innerHTML

      # Get navigation items
      navItems = @getNavItems()

      # Get container options from global config
      containerOptions = @getContainerOptions()

      # Prepare render options
      renderOptions = @getRenderOptions()

      # Render glass component
      @glassContainer = @renderGlassComponent(
        navItems,
        containerOptions,
        renderOptions,
      )

      # Apply post-render customizations
      @postRenderSetup()

      console.log "[EnhancedGlassController] Glass initialized successfully"
    catch error
      console.error "[EnhancedGlassController] Error initializing glass:", error
      @setupFallback()

  # Re-initialize glass with current config
  reinitializeGlass: ->
    return unless @shouldEnableGlass()

    # Clean up existing glass
    @cleanupGlass()
    
    # Re-initialize with current config
    @initializeGlass()

  getNavItems: ->
    # Try to get nav items from data attribute
    navItemsData = @data.get("nav-items") or @element.dataset.navItems
    return [] unless navItemsData

    try
      rawNavItems = JSON.parse navItemsData

      # Transform items to include click handlers and update navigation store
      rawNavItems.map (item) =>
        {
          ...item,
          text: item.text or "",
          onClick: => @handleNavClick(item),
        }
    catch error
      console.error "[EnhancedGlassController] Failed to parse nav items:", error
      []

  getContainerOptions: ->
    # Get base config from global store
    globalConfig = @glassConfigStoreValue
    
    # Merge with any component-specific overrides
    options = {
      type: globalConfig.glassType,
      borderRadius: globalConfig.borderRadius,
      tintOpacity: globalConfig.tintOpacity,
      parallaxSpeed: globalConfig.parallaxSpeed,
      parallaxOffset: globalConfig.parallaxOffset,
      syncWithParallax: globalConfig.syncWithParallax,
      backgroundParallaxSpeed: globalConfig.backgroundParallaxSpeed,
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
      renderLiquidGlassDrawer(@element, containerOptions, renderOptions)
    else if componentType is "sidebar" and cornerRounding is "right"
      renderLiquidGlassSidebarRightRounded(@element, navItems, containerOptions, renderOptions)
    else if componentType is "nav" or componentType is "sidebar"
      renderLiquidGlassNav(@element, navItems, containerOptions, renderOptions)
    else
      # For other component types, use basic nav renderer
      renderLiquidGlassNav(@element, navItems, containerOptions, renderOptions)

  postRenderSetup: ->
    # Mark current page items as disabled if this is a navigation component
    if @componentTypeValue is "nav" or @componentTypeValue is "sidebar"
      @markCurrentPageItems()

    # Apply any custom post-render logic (can be overridden by subclasses)
    @customPostRenderSetup()

  markCurrentPageItems: ->
    currentPath = @navigationStoreValue.currentPath
    
    # Find and mark current page items
    navLinks = @element.querySelectorAll("[data-nav-item]")
    navLinks.forEach (link) =>
      itemPath = link.getAttribute("href") or link.dataset.path
      if itemPath and itemPath is currentPath
        link.classList.add("current-page")
        link.setAttribute("aria-current", "page")
        
        # Update navigation store
        @navigationStoreValue = {
          ...@navigationStoreValue,
          activeItem: link.dataset.navItem or itemPath
        }

  customPostRenderSetup: ->
    # Override in subclasses for custom behavior
    console.log "[EnhancedGlassController] Custom post-render setup"

  handleNavClick: (item) ->
    console.log "[EnhancedGlassController] Nav item clicked:", item

    # Update navigation store
    @navigationStoreValue = {
      ...@navigationStoreValue,
      currentPath: item.path,
      activeItem: item.path
    }

    # Handle navigation based on method
    if item.method and item.method isnt "get"
      # Handle non-GET requests
      @handleFormNavigation(item)
    else
      # Handle regular navigation
      @handleRegularNavigation(item)

  handleFormNavigation: (item) ->
    # Create and submit a form for non-GET requests
    form = document.createElement("form")
    form.method = "post"
    form.action = item.path
    form.style.display = "none"

    # Add method override if needed
    if item.method and item.method isnt "post"
      methodInput = document.createElement("input")
      methodInput.type = "hidden"
      methodInput.name = "_method"
      methodInput.value = item.method
      form.appendChild(methodInput)

    # Add CSRF token
    csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")
    if csrfToken
      csrfInput = document.createElement("input")
      csrfInput.type = "hidden"
      csrfInput.name = "authenticity_token"
      csrfInput.value = csrfToken
      form.appendChild(csrfInput)

    document.body.appendChild(form)
    form.submit()

  handleRegularNavigation: (item) ->
    # Use Turbo for regular navigation
    Turbo.visit(item.path)

  setupFallback: ->
    # Add fallback classes for CSS-only styling
    @element.classList.add("glass-fallback")
    console.log "[EnhancedGlassController] Using CSS fallback"

  cleanupGlass: ->
    # Clean up WebGL resources and restore original content
    if @glassContainer
      try
        # Call cleanup method if available
        if typeof @glassContainer.cleanup is "function"
          @glassContainer.cleanup()
      catch error
        console.error "[EnhancedGlassController] Error during glass cleanup:", error

    # Restore original content
    if @originalContent
      @element.innerHTML = @originalContent

    @glassContainer = undefined
    @element.classList.remove("glass-active")

    console.log "[EnhancedGlassController] Glass cleaned up"

  # Utility methods for external access
  updateGlassConfig: (config) ->
    @glassConfigStoreValue = { ...@glassConfigStoreValue, ...config }

  toggleGlass: ->
    currentTheme = @themeStoreValue
    @themeStoreValue = { ...currentTheme, glassEnabled: not currentTheme.glassEnabled }

  isGlassEnabled: ->
    @shouldEnableGlass()

  getCurrentConfig: ->
    @glassConfigStoreValue
