import { Controller } from "@hotwired/stimulus"

# This controller is attached directly to individual toast elements.
# It handles auto-hiding and manual dismissal for that specific toast.
export default class extends Controller
  @values = {
    # Timeout in milliseconds before auto-hiding. 0 disables auto-hide.
    timeout: { type: Number, default: 5000 }
  }

  connect: ->
    # Start hidden, then transition to visible
    @element.style.opacity = 0
    # Use requestAnimationFrame to ensure the transition applies after initial render
    requestAnimationFrame =>
      @element.style.opacity = 1
      @element.style.transform = "translateY(0)" # Assuming initial CSS might have it translated
      return

    # Set up a timer to auto-dismiss the toast if timeout is positive
    if @timeoutValue > 0
      @dismissTimer = setTimeout (=>
        @dismiss()
        return
      ), @timeoutValue
    return

  disconnect: ->
    # Clean up the timer when the controller is disconnected (e.g., element removed)
    if @dismissTimer
      clearTimeout @dismissTimer
    return

  # Action method called by the close button (data-action="toast#dismiss")
  dismiss: ->
    # Prevent multiple dismiss calls if already dismissing
    return if @isDismissing
    @isDismissing = true

    # Clear the auto-hide timer if it exists
    if @dismissTimer
      clearTimeout @dismissTimer

    # Add animation classes/styles for fade-out/slide-up
    @element.style.opacity = 0
    @element.style.transform = "translateY(-10px)" # Example: slide up slightly
    # Use transitionend event for more robust removal, but setTimeout is simpler here

    # Wait for the animation (defined in CSS transition) to complete before removing the element
    # Ensure this timeout matches your CSS transition duration for opacity/transform
    setTimeout (=>
      @element.remove()
      return
    ), 300 # Assuming a 300ms transition in CSS
    return