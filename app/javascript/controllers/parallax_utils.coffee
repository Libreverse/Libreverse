# parallax_utils.coffee
# Shared utility for LocomotiveScroll-based parallax effects

# Sets up a parallax effect on the given element using LocomotiveScroll.
# Returns a cleanup function to remove the effect.
# Usage:
#   cleanup = setupLocomotiveScrollParallax(element, speed, context)
#   cleanup() # to remove
setupLocomotiveScrollParallax = (element, speed = -2, context = null) ->
  # Find the LocomotiveScroll instance
  locomotiveController = document.querySelector('[data-controller="locomotive-scroll"]')
  if not locomotiveController?
    return -> return

  scrollInstance = locomotiveController?.__stimulus_controller__?.scroll
  scrollInstance ?= window.locomotiveScrollInstance
  if not scrollInstance?
    return -> return

  handler = (args) =>
    y = args?.scroll?.y or 0
    element.style.transform = "translate3d(0, #{y * speed * 0.1}px, 0)"
  # If context is provided, bind handler to it (for @ in class)
  handler = handler.bind(context) if context?

  scrollInstance.on? 'scroll', handler

  # Return cleanup function
  ->
    scrollInstance.off? 'scroll', handler
    element.style.transform = ''

# Export for use in controllers
export { setupLocomotiveScrollParallax }
