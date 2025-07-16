import { Controller } from "@hotwired/stimulus"
import GlassController from "./glass_controller"

# SidebarController - extends GlassController for sidebar navigation
# Glass effect applied only to sidebar background, buttons use CSS
export default class extends GlassController
  # Define values that can be fed via data attributes
  @values = {
    ...GlassController.values,
    componentType: { type: String, default: "sidebar" },
  }

  initialize: ->
    console.log "[SidebarController] initialized", @element

  connect: ->
    console.log "[SidebarController] Connected to sidebar"

    # Call parent connect which will handle glass enhancement for background only
    super()

  # Custom post-render setup for sidebar
  customPostRenderSetup: ->
    console.log "[SidebarController] Custom post-render setup for sidebar"

    # Apply any sidebar-specific enhancements
    @setupSidebarInteractions()

  setupSidebarInteractions: ->
    # Add hover effects or other sidebar-specific interactions
    @element.addEventListener "mouseenter", =>
      @element.classList.add("sidebar-hover")

    @element.addEventListener "mouseleave", =>
      @element.classList.remove("sidebar-hover")

  # Action to refresh sidebar glass
  refresh: ->
    console.log "[SidebarController] Refresh action triggered"
    super()
