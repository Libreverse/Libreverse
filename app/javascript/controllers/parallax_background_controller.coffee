import ApplicationController from "./application_controller"
import { setupLocomotiveScrollParallax } from "./parallax_utils.coffee"

# ParallaxBackgroundController
# Adds a subtle parallax translate effect to the element it is
# attached to, synchronising with the global LocomotiveScroll instance.
#
# Usage (HAML example):
#   %div.administrative-background{
#     "data-controller" => "parallax-background",
#     "data-scroll" => "",
#     "data-scroll-speed" => "-3",  # optional, defaults to -2
#   }
#
# The `data-scroll-speed` attribute mirrors LocomotiveScroll's API and
# indicates how fast the element moves relative to the scroll.
export default class extends ApplicationController
  @values =
    speed: { type: Number, default: -2 }

  connect: ->
    super.connect()
    @removeLocomotiveScrollParallax = setupLocomotiveScrollParallax(@element, @speedValue, @)
    return

  disconnect: ->
    super.disconnect()
    @removeLocomotiveScrollParallax?()
    return

  # ------------------------------------------------------------------
  # Private helpers
  # ------------------------------------------------------------------

  # Remove the setupLocomotiveScrollParallax method entirely
