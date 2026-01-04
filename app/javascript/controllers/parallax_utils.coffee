# parallax_utils.coffee
# Shared utility for Lenis-based parallax effects

# Sets up a parallax effect on the given element using Lenis.
# Returns a cleanup function to remove the effect.
# Usage:
#   cleanup = setupLocomotiveScrollParallax(element, speed, context)
#   cleanup() # to remove
setupLocomotiveScrollParallax = (element, speed = -2, context = null) ->
  # Performance optimizations
  element.style.willChange = 'transform'
  element.style.backfaceVisibility = 'hidden'
  element.style.perspective = '1000px'
  
  # Throttle updates to 60fps max
  lastUpdate = 0
  rafId = null
  
  throttledUpdate = (transformValue) ->
    now = performance.now()
    if now - lastUpdate < 16.67 # 60fps throttle
      if rafId
        cancelAnimationFrame(rafId)
      rafId = requestAnimationFrame ->
        element.style.transform = transformValue
        rafId = null
        lastUpdate = performance.now()
    else
      element.style.transform = transformValue
      lastUpdate = now

  # Use Lenis instance (exposed globally by lenis_controller)
  lenisInstance = window.lenis
  if not lenisInstance?
    # Fallback: listen for lenis-scroll custom event
    handler = (event) =>
      y = event?.detail?.scroll or 0
      transformValue = "translate3d(0, #{y * speed * 0.1}px, 0)"
      throttledUpdate(transformValue)
    handler = handler.bind(context) if context?
    
    document.addEventListener 'lenis-scroll', handler
    
    # Return cleanup function
    return ->
      document.removeEventListener 'lenis-scroll', handler
      if rafId
        cancelAnimationFrame(rafId)
      element.style.transform = ''
      element.style.willChange = 'auto'

  handler = (args) =>
    y = args?.scroll or 0
    transformValue = "translate3d(0, #{y * speed * 0.1}px, 0)"
    throttledUpdate(transformValue)
  # If context is provided, bind handler to it (for @ in class)
  handler = handler.bind(context) if context?

  lenisInstance.on? 'scroll', handler

  # Return cleanup function
  ->
    lenisInstance.off? 'scroll', handler
    if rafId
      cancelAnimationFrame(rafId)
    element.style.transform = ''
    element.style.willChange = 'auto'
    element.style.backfaceVisibility = ''
    element.style.perspective = ''

# Export for use in controllers
export { setupLocomotiveScrollParallax }
