import { Controller } from "@hotwired/stimulus"

# This controller is attached directly to individual toast elements.
# It handles auto-hiding and manual dismissal for that specific toast.
export default class extends Controller
  @values = {
    timeout: { type: Number, default: 5000 }
  }

  connect: ->
    # Start hidden, transition to visible using rAF for timing
    @element.style.opacity = 0
    requestAnimationFrame =>
      @element.style.opacity = 1
      @element.style.transform = "translateY(0)" # Assume initial CSS transform
      return

    # Set up auto-dismiss timer
    if @timeoutValue > 0
      @dismissTimer = setTimeout (=>
        @dismiss()
        return
      ), @timeoutValue
    return

  disconnect: ->
    # Clean up the timer on disconnect
    if @dismissTimer
      clearTimeout @dismissTimer
    return

  dismiss: ->
    # Prevent multiple dismiss calls
    return if @isDismissing
    @isDismissing = true

    # Clear any auto-hide timer
    if @dismissTimer
      clearTimeout @dismissTimer

    # Trigger fade-out/slide-up animation
    @element.style.opacity = 0
    @element.style.transform = "translateY(-10px)"

    # Remove element after CSS transition (match duration in CSS)
    setTimeout (=>
      @element.remove()
      return
    ), 300 # Match CSS transition duration
    return
