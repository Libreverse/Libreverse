import GlassController from "./glass_controller"

###
Card Controller - extends GlassController for card components
###
export default class extends GlassController
  @values = {
    ...GlassController.values,
    # Override defaults for cards
    componentType: { type: String, default: "card" },
    cornerRounding: { type: String, default: "all" },
    borderRadius: { type: Number, default: 15 },
    tintOpacity: { type: Number, default: 0.08 },
  }

  connect: ->
    console.log "[CardController] Connected"
    super()

  # Override to disable navigation-specific features for cards
  getNavItems: ->
    # Cards don't typically have nav items
    []

  # Override navigation handling since cards don't navigate
  handleNavClick: (item) ->
    # Custom card click behavior can be implemented here
    console.log "[CardController] Card clicked:", item

    # Emit custom event for card interactions
    @element.dispatchEvent(new CustomEvent("card:click", {
      detail: { item },
      bubbles: true,
    }))

  customPostRenderSetup: ->
    # Card-specific logic
    console.log "[CardController] Custom post-render setup"

    # Add hover effects for cards
    glassButtons = @element.querySelectorAll ".glass-button"
    for button in glassButtons
      button.addEventListener "mouseenter", =>
        button.style.transform = "scale(1.02)"

      button.addEventListener "mouseleave", =>
        button.style.transform = "scale(1)"
