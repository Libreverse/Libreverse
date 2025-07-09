import GlassController from "./glass_controller"

###
Button Controller - extends GlassController for standalone button components
###
export default class extends GlassController
  @values = {
    ...GlassController.values,
    # Override defaults for buttons
    componentType: { type: String, default: "button" },
    cornerRounding: { type: String, default: "all" },
    borderRadius: { type: Number, default: 25 },
    glassType: { type: String, default: "pill" },
    tintOpacity: { type: Number, default: 0.15 },

    # Button-specific values
    buttonText: { type: String, default: "" },
    buttonIcon: { type: String, default: "" },
    buttonPath: { type: String, default: "" },
    buttonMethod: { type: String, default: "get" },
  }

  connect: ->
    console.log "[ButtonController] Connected"
    super()

  # Override to create button-specific nav items
  getNavItems: ->
    # Create a single nav item for this button
    [
      {
        text: @buttonTextValue,
        path: @buttonPathValue,
        icon: @buttonIconValue,
        method: @buttonMethodValue,
        svg: @extractSvgFromButton(),
      }
    ]

  extractSvgFromButton: ->
    # Try to extract SVG content from the button
    svg = @element.querySelector "svg"
    if svg then svg.outerHTML else ""

  # Override navigation handling for single buttons
  handleNavClick: (item) =>
    # Single button navigation
    if item.path
      @navigate item
    else
      # Emit custom event for button interactions
      @element.dispatchEvent(new CustomEvent("button:click", {
        detail: { item },
        bubbles: true,
      }))

  customPostRenderSetup: =>
    # Button-specific logic
    console.log "[ButtonController] Custom post-render setup"

    # Add press effect for buttons
    glassButtons = @element.querySelectorAll ".glass-button"
    for button in glassButtons
      button.addEventListener "mousedown", =>
        button.style.transform = "scale(0.95)"

      button.addEventListener "mouseup", =>
        button.style.transform = "scale(1)"

      button.addEventListener "mouseleave", =>
        button.style.transform = "scale(1)"
