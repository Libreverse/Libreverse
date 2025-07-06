import GlassController from "./glass_controller"

###
Navigation Controller - extends GlassController for navigation bars
###
export default class extends GlassController
  @values = {
    ...GlassController.values,
    # Override defaults for navigation
    componentType: { type: String, default: "nav" },
    cornerRounding: { type: String, default: "all" },
    borderRadius: { type: Number, default: 10 },
  }

  connect: ->
    console.log "[NavController] Connected"
    super()

  # Override to add nav-specific post-render setup
  customPostRenderSetup: ->
    # Navigation-specific logic can go here
    console.log "[NavController] Custom post-render setup"
