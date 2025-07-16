{ Controller } = require '@hotwired/stimulus'
{ useStore } = require 'stimulus-store'
{ themeStore, glassConfigStore, navigationStore } = require '../stores'
{ enhanceWithGlass, removeGlassEnhancement, hasGlassEnhancement } = require '../libs/simplified_glass.js'
{ validateLiquidGlass } = require '../libs/liquid_glass.js'

###
# Glass Controller with simplified integration - Works with existing HTML structure
# Minimizes DOM manipulation by enhancing existing elements instead of recreating them
#
# Usage:
# 1. Add data-controller="glass" to any element
# 2. Configure with data-glass-*-value attributes
# 3. Element will be enhanced with glass effects while preserving existing HTML structure
###
class DefaultExport extends Controller
  @stores = [themeStore, glassConfigStore, navigationStore]

  @values = {
    # Core glass configuration
    enableGlass: { type: Boolean, default: true },
    componentType: { type: String, default: "nav" }, # "nav", "sidebar", "drawer", "button", "card"
    borderRadius: { type: Number, default: 12 },
    tintOpacity: { type: Number, default: 0.12 },
    cornerRounding: { type: String, default: "all" }, # "all", "right", "left", "top", "bottom"

    # Enable/disable overrides
    forceEnable: { type: Boolean, default: false },
    forceDisable: { type: Boolean, default: false },
  }

  connect: ->
    console.log "[GlassController] Connected to:", @element.className

    # Set up stimulus-store
    useStore(@)

    @isConnected = true
    @fallbackActive = false

    # Set up listeners
    @setupGlassConfigListener()
    @registerWithFallbackMonitor()

    # Initialize glass enhancement if enabled
    if @shouldEnableGlass()
      @enhanceElement()
    else
      @setupFallback()

  disconnect: ->
    console.log "[GlassController] Disconnecting from:", @element.className
    @cleanupGlass()
    @isConnected = false

  # --- Glass Enhancement Methods ---

  enhanceElement: ->
    return if hasGlassEnhancement(@element)

    console.log "[GlassController] Enhancing element with glass"

    options = {
      componentType: @componentTypeValue,
      borderRadius: @borderRadiusValue,
      tintOpacity: @tintOpacityValue,
      cornerRounding: @cornerRoundingValue
    }

    enhanceWithGlass(@element, options)
      .then (result) =>
        if result
          console.log "[GlassController] Glass enhancement successful"
          @element.dataset.glassActive = "true"
          @postRenderSetup()
        else
          console.log "[GlassController] Glass enhancement failed, using fallback"
          @setupFallback()
      .catch (error) =>
        console.error "[GlassController] Glass enhancement error:", error
        @setupFallback()

  cleanupGlass: ->
    return unless hasGlassEnhancement(@element)

    console.log "[GlassController] Cleaning up glass enhancement"
    removeGlassEnhancement(@element)
    delete @element.dataset.glassActive

  setupFallback: ->
    console.log "[GlassController] Glass not available - using CSS fallback"
    @fallbackActive = true
    # No additional classes needed - sidebar.scss handles the default state
    delete @element.dataset.glassActive

  # --- Configuration Methods ---

  shouldEnableGlass: ->
    return false if @forceDisableValue
    return true if @forceEnableValue
    return @enableGlassValue and validateLiquidGlass(@element)

  # --- Post-render setup for subclasses ---

  postRenderSetup: ->
    @customPostRenderSetup?()

  handleNavClick: (item) ->
    # Default navigation handling - can be overridden by subclasses
    console.log "[GlassController] Navigation click:", item

    if item.onClick
      item.onClick()
    else if item.path
      window.location.href = item.path

  # --- Configuration and monitoring methods ---

  setupGlassConfigListener: ->
    # Listen for global glass config updates from stimulus-store
    try
      @glassConfigStore?.subscribe (config) =>
        return unless @isConnected

        # Update values from global config
        @enableGlassValue = config.enabled if config.enabled?
        @borderRadiusValue = config.borderRadius if config.borderRadius?
        @tintOpacityValue = config.tintOpacity if config.tintOpacity?

        # Re-enhance element with new config
        @refreshGlass()
    catch error
      console.warn "[GlassController] Glass config listener setup failed:", error

  registerWithFallbackMonitor: ->
    try
      if window.glassFallbackMonitor
        # Add observer to monitor fallback triggers
        @fallbackObserver = (reason) =>
          console.warn "[GlassController] Fallback triggered:", reason
          @setupFallback() unless @fallbackActive

        window.glassFallbackMonitor.addObserver(@fallbackObserver)

      # Listen for fallback events
      @element.addEventListener "glass:fallbackActivated", @handleFallbackActivated.bind(@)
    catch error
      console.warn "[GlassController] Fallback monitor setup failed:", error

  handleFallbackActivated: (event) ->
    console.log "[GlassController] Glass fallback activated:", event.detail.error
    @setupFallback() unless @fallbackActive

  refreshGlass: ->
    return unless @isConnected

    if @shouldEnableGlass()
      @cleanupGlass()
      @enhanceElement()
    else
      @cleanupGlass()
      @setupFallback()

  # --- Value Change Callbacks ---

  enableGlassValueChanged: ->
    @refreshGlass()

  componentTypeValueChanged: ->
    @refreshGlass()

  borderRadiusValueChanged: ->
    @refreshGlass()

  tintOpacityValueChanged: ->
    @refreshGlass()

  cornerRoundingValueChanged: ->
    @refreshGlass()

  # --- Action Methods ---

  # Action to manually refresh glass effect
  refresh: ->
    console.log "[GlassController] Manual refresh triggered"
    @refreshGlass()

  # Action to toggle glass effect
  toggle: ->
    console.log "[GlassController] Toggle triggered"
    @enableGlassValue = not @enableGlassValue

  # Action to enable glass effect
  enable: ->
    console.log "[GlassController] Enable triggered"
    @enableGlassValue = true

  # Action to disable glass effect
  disable: ->
    console.log "[GlassController] Disable triggered"
    @enableGlassValue = false

module.exports = DefaultExport
