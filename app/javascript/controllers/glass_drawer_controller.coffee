import GlassController from "./glass_controller"
import StimulusReflex from "stimulus_reflex"
import { enhanceWithGlass } from "../libs/simplified_glass.js"

###
Drawer Controller - extends GlassController for drawer/modal components
Uses simplified glass integration with minimal DOM manipulation
###
export default class extends GlassController
  @values = {
    ...GlassController.values,
    componentType: { type: String, default: "drawer" },
    expanded: { type: Boolean, default: false },
    drawerId: { type: String, default: "main" },
    height: { type: Number, default: 60 },
    expandedHeight: { type: Number, default: 600 },
  }

  @targets = ["drawer", "overlay", "content", "icon"]

  connect: ->
    console.log "[GlassDrawerController] Connected to drawer"

    # Register with StimulusReflex
    StimulusReflex.register(@)

    # Set up event listeners
    @setupEventListeners()

    # Store initial state
    @_initialExpanded = @expandedValue

    # Call parent connect which will handle glass enhancement
    super()

    # Initial UI setup
    requestAnimationFrame =>
      @updateUI()

  setupEventListeners: ->
    @boundHandleKeydown = @handleKeydown.bind(@)
    @boundDrawerEventHandler = @handleDrawerEvent.bind(@)

    document.addEventListener("keydown", @boundHandleKeydown)
    document.addEventListener("drawer:toggle", @boundDrawerEventHandler)

  disconnect: ->
    document.removeEventListener("keydown", @boundHandleKeydown)
    document.removeEventListener("drawer:toggle", @boundDrawerEventHandler)
    super()

  # Override glass enhancement to work with drawer structure
  enhanceElement: ->
    # Find the actual drawer element
    drawerElement = @element.querySelector(".drawer") or @element

    # Apply glass enhancement to the drawer element
    options = {
      componentType: @componentTypeValue,
      borderRadius: @borderRadiusValue,
      tintOpacity: @tintOpacityValue,
      cornerRounding: @cornerRoundingValue
    }

    enhanceWithGlass(drawerElement, options)
      .then (result) =>
        if result
          console.log "[GlassDrawerController] Glass enhancement successful"
          @element.classList.add("glass-enhanced")
          @element.dataset.glassActive = "true"
          @customPostRenderSetup()
        else
          console.log "[GlassDrawerController] Glass enhancement failed, using fallback"
          @setupFallback()
      .catch (error) =>
        console.error "[GlassDrawerController] Glass enhancement error:", error
        @setupFallback()

  # Custom post-render setup for drawer
  customPostRenderSetup: ->
    console.log "[GlassDrawerController] Custom post-render setup for drawer"

    # Ensure drawer styling is preserved
    @element.classList.add("drawer-enhanced")

    # Apply drawer-specific styling
    @setupDrawerStyling()

  setupDrawerStyling: ->
    drawerElement = @element.querySelector(".drawer")
    return unless drawerElement

    # Ensure drawer background is transparent to show glass effect
    drawerElement.style.background = "transparent"
    drawerElement.style.backdropFilter = "none"

    # Apply subtle overlay styling to content areas
    @applyContentStyling()

  applyContentStyling: ->
    # Add subtle styling to header and content areas
    header = @element.querySelector(".drawer-header")
    if header
      header.style.background = "rgba(255, 255, 255, 0.05)"
      header.style.borderBottom = "1px solid rgba(255, 255, 255, 0.1)"

    content = @element.querySelector(".drawer-content-container")
    if content
      content.style.background = "rgba(255, 255, 255, 0.02)"

  # --- Drawer Actions ---

  ###
  Toggles the drawer state immediately on the client-side.
  Server state is updated asynchronously for persistence only.
  ###
  toggle: (event) ->
    event?.preventDefault()

    # Immediate UI update - no waiting for server
    @expandedValue = not @expandedValue

    # Fire-and-forget server update for persistence
    # Use setTimeout to ensure this doesn't block the UI update
    setTimeout =>
      @stimulate "DrawerReflex#toggle", {
        drawer_id: @drawerIdValue,
        expanded: @expandedValue,
      }
    , 0

  ###
  Opens the drawer immediately if it is not already open.
  ###
  open: ->
    return if @expandedValue

    # Immediate UI update
    @expandedValue = true

    # Fire-and-forget server update
    setTimeout =>
      @stimulate "DrawerReflex#toggle", {
        drawer_id: @drawerIdValue,
        expanded: true,
      }
    , 0

  ###
  Closes the drawer immediately if it is not already closed.
  ###
  close: ->
    return unless @expandedValue

    # Immediate UI update
    @expandedValue = false

    # Fire-and-forget server update
    setTimeout =>
      @stimulate "DrawerReflex#toggle", {
        drawer_id: @drawerIdValue,
        expanded: false,
      }
    , 0

  # --- Event Handlers ---

  handleDrawerEvent: (event) ->
    return unless event.detail.drawerId is @drawerIdValue

    if event.detail.open
      @open()
    else if event.detail.close
      @close()

  handleKeydown: (event) ->
    if event.key is "Escape" and @expandedValue
      @close()

  # --- UI Update Methods ---

  ###
  Centralized method to update all UI components based on the current state.
  ###
  updateUI: ->
    @updateDrawerHeight()
    @updateAriaExpanded()
    @updateToggleIcon()

  ###
  Smoothly transitions the drawer's height.
  ###
  updateDrawerHeight: ->
    return unless @hasDrawerTarget and @hasContentTarget

    drawer = @drawerTarget
    content = @contentTarget

    targetHeight = if @expandedValue then "#{@expandedHeightValue}px" else "#{@heightValue}px"
    contentHeight = if @expandedValue then "#{@expandedHeightValue - @heightValue}px" else "0px"

    drawer.style.height = targetHeight
    content.style.height = contentHeight
    drawer.classList.toggle "drawer-expanded", @expandedValue

    # Only refresh glass if glass is actually enabled
    if @enableGlassValue and @glassContainer
      @refreshGlass()

  ###
  Updates ARIA attributes for accessibility.
  ###
  updateAriaExpanded: ->
    if @hasDrawerTarget
      @drawerTarget.setAttribute "aria-expanded", @expandedValue.toString()

  ###
  Rotates the toggle icon to indicate state.
  ###
  updateToggleIcon: ->
    if @hasIconTarget
      @iconTarget.classList.toggle "rotated", @expandedValue

  # --- Value Change Callbacks ---

  ###
  This is the primary driver of UI changes. It is called automatically by Stimulus
  whenever `this.expandedValue` is changed.
  ###
  expandedValueChanged: ->
    console.log "[GlassDrawerController] Expanded state changed to: #{@expandedValue}"
    @updateUI()

    # Dispatch events to notify other parts of the application.
    eventName = if @expandedValue then "drawer:opened" else "drawer:closed"
    @element.dispatchEvent(new CustomEvent(eventName, {
      detail: { drawerId: @drawerIdValue },
      bubbles: true,
    }))
