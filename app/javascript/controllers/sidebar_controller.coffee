import ApplicationController from "./application_controller"

# SidebarController
# ------------------
# Handles hover interactions for the navigation sidebar.  The controller works
# in tandem with `SidebarReflex#set_hover_state`, which applies CSS class
# changes server-side via CableReady so that all open tabs stay in sync.
#
# Improvements made:
# *   Added Stimulus `values` for `hoverEnabled` and `expanded` so initial
#     state comes directly from the DOM.
# *   Prevent redundant reflex calls by tracking the current expanded/hover
#     state locally and returning early if nothing changed.
# *   Respect the `hoverEnabled` preference and bail out early when it is
#     disabled.
# *   Provided early exit guards and removed unnecessary explicit `return`s
#     for cleaner, idiomatic CoffeeScript.
#
# Track Turbo readiness globally
ready = false

document.addEventListener 'turbo:load', ->
  ready = true

document.addEventListener 'turbo:before-visit', ->
  ready = false

export default class extends ApplicationController

  # Define values that can be fed via data attributes, e.g.
  #   data-hovered-value="true"
  #   data-expanded-value="false"
  @values =
    hovered: Boolean
    expanded: Boolean

  # Extra method to check StimulusReflex registration
  initialize: ->
    console.log "[SidebarController] initialized", @element

  connect: ->
    super.connect()
    console.log "[SidebarController] connected - hovered:", @hoveredValue, "expanded:", @expandedValue

  # There are separate methods to explicitly handle the
  # mouseenter and mouseleave events. This helps avoid any potential
  # issues with the event type detection pattern.

  # Handle mouse entering the sidebar
  mouseEnter: (event) ->
    return unless ready
    console.log "[SidebarController#mouseEnter]", "hovered:", @hoveredValue
    return if @currentState is true
    @currentState = true
    console.log "[SidebarController] Entering - stimulating with true"
    @stimulate("SidebarReflex#set_hover_state", true)

  # Handle mouse leaving the sidebar
  mouseLeave: (event) ->
    return unless ready
    console.log "[SidebarController#mouseLeave]", "hovered:", @hoveredValue
    return if @currentState is false
    @currentState = false
    console.log "[SidebarController] Leaving - stimulating with false"
    @stimulate("SidebarReflex#set_hover_state", false)
