import GlassController from "./glass_controller"
import StimulusReflex from "stimulus_reflex"

###
Drawer Controller - extends GlassController for drawer/modal components
Manages the state of a drawer, with optimistic UI updates and backend state synchronization.
###
export default class extends GlassController
  @values = {
    ...GlassController.values,
    componentType: { type: String, default: "drawer" },
    cornerRounding: { type: String, default: "top" },
    borderRadius: { type: Number, default: 20 },
    tintOpacity: { type: Number, default: 0.1 },
    expanded: { type: Boolean, default: false },
    drawerId: { type: String, default: "main" },
    height: { type: Number, default: 60 },
    expandedHeight: { type: Number, default: 600 },
  }

  @targets = ["drawer", "overlay", "content", "icon"]

  connect: ->
    super()
    console.log "[GlassDrawerController] Connected", {
      element: @element,
      expanded: @expandedValue,
    }

    # Register with StimulusReflex to enable `this.stimulate`
    StimulusReflex.register @

    @boundHandleKeydown = @handleKeydown.bind @
    @boundDrawerEventHandler = @handleDrawerEvent.bind @
    document.addEventListener "keydown", @boundHandleKeydown
    document.addEventListener "drawer:toggle", @boundDrawerEventHandler

    # Store initial state to prevent unwanted resets
    @_initialExpanded = @expandedValue

    # Initial UI setup based on the starting `expandedValue`
    # Defer UI update until the next frame to ensure targets are available.
    requestAnimationFrame =>
      @updateUI()

  disconnect: ->
    document.removeEventListener "keydown", @boundHandleKeydown
    document.removeEventListener "drawer:toggle", @boundDrawerEventHandler
    super()

  # Drawers do not have navigation items.
  getNavItems: ->
    []

  # No special click handling needed for the drawer itself.
  handleNavClick: ->

  # This can be simplified or removed if styling is handled by CSS.
  customPostRenderSetup: ->
    console.log "[GlassDrawerController] Custom post-render setup"
    # Ensure glass initialization doesn't change the drawer state
    # Preserve the current expanded state
    currentExpanded = @expandedValue

    # After glass setup, restore the state if it was changed
    requestAnimationFrame =>
      if @expandedValue isnt currentExpanded
        console.log "[GlassDrawerController] Restoring expanded state after glass setup:", currentExpanded
        @expandedValue = currentExpanded

  # StimulusReflex lifecycle callbacks
  beforeReflex: ->
    # Called before reflex actions - no special handling needed
    console.log "[GlassDrawerController] Before reflex - UI already updated"

  afterReflex: (element, reflex) ->
    console.log "[GlassDrawerController] After reflex:", reflex
    # Server acknowledgment received - no UI changes needed as they were already applied optimistically

  reflexError: (element, reflex, error) ->
    console.error "[GlassDrawerController] Reflex error:", error
    # On error, we could potentially revert the UI state here if needed

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
    @element.dispatchEvent new CustomEvent eventName, {
      detail: { drawerId: @drawerIdValue },
      bubbles: true,
    }
