import { Controller } from "@hotwired/stimulus"

# Utility function for linear interpolation.
# @param {number} start - Starting value.
# @param {number} end - Ending value.
# @param {number} amt - Interpolation factor between 0 and 1.
# @returns {number} - Interpolated value.
lerp = (start, end, amt) ->
  (1 - amt) * start + amt * end

export default class extends Controller
  connect: ->
    @circle = @element.querySelector(".custom-cursor-circle")
    @dot = @element.querySelector(".cursor-dot")
    
    # Bind methods
    @handleMouseMove = @handleMouseMove.bind(@)
    @animateCursor = @animateCursor.bind(@)
    @handleMouseDown = @handleMouseDown.bind(@)
    @handleMouseUp = @handleMouseUp.bind(@)
    @saveCursorState = @saveCursorState.bind(@)
    @loadCursorState = @loadCursorState.bind(@)
    @finishInitialization = @finishInitialization.bind(@)
    @handleMouseLeave = @handleMouseLeave.bind(@)
    @handleMouseEnter = @handleMouseEnter.bind(@)
    
    # Track initialization state
    @isInitializing = true
    @hasUserMovedMouse = false
    @isMouseInWindow = true

    # Add event listeners
    globalThis.addEventListener("mousemove", @handleMouseMove)
    globalThis.addEventListener("mousedown", @handleMouseDown)
    globalThis.addEventListener("mouseup", @handleMouseUp)
    document.addEventListener("turbo:before-visit", @saveCursorState)
    document.addEventListener("turbo:load", @loadCursorState)
    document.addEventListener("mouseleave", @handleMouseLeave)
    document.addEventListener("mouseenter", @handleMouseEnter)

    # Set default values (a reasonable but arbitrary position)
    @isShrinking = false
    @circleX = window.innerWidth / 2
    @circleY = window.innerHeight / 2
    @dotX = @circleX - 8
    @dotY = @circleY - 8
    @targetX = @circleX
    @targetY = @circleY
    
    # Apply no-transition class during initialization
    @circle?.classList.add("no-transition")
    
    # Load saved state (position and shrink state)
    @loadCursorState()
    
    # Start animation loop
    requestAnimationFrame(@animateCursor)

  disconnect: ->
    # Clear the timeout if it exists
    if @initTimeout
      clearTimeout(@initTimeout)
      @initTimeout = null
      
    # Save state before disconnecting
    @saveCursorState()
    
    # Remove event listeners
    globalThis.removeEventListener("mousemove", @handleMouseMove)
    globalThis.removeEventListener("mousedown", @handleMouseDown)
    globalThis.removeEventListener("mouseup", @handleMouseUp)
    document.removeEventListener("turbo:before-visit", @saveCursorState)
    document.removeEventListener("turbo:load", @loadCursorState)
    document.removeEventListener("mouseleave", @handleMouseLeave)
    document.removeEventListener("mouseenter", @handleMouseEnter)

  # Finish initialization immediately using current position data
  finishInitialization: ->
    if @isInitializing
      # Set ring position with no transition
      @circle?.style.setProperty("--translate-x", "#{@circleX}px")
      @circle?.style.setProperty("--translate-y", "#{@circleY}px")
      
      # Set dot position with no transition
      @dot?.style.setProperty("--translate-x", "#{@dotX}px")
      @dot?.style.setProperty("--translate-y", "#{@dotY}px")
      
      # Force browser to apply position before making visible
      if @circle
        window.getComputedStyle(@circle).opacity
      if @dot
        window.getComputedStyle(@dot).opacity
      
      # Make visible with no transition
      @isInitializing = false
      @circle?.classList.remove("initializing")
      @dot?.classList.remove("initializing")
      
      # Remove no-transition class immediately
      @circle?.classList.remove("no-transition")
      @dot?.classList.remove("no-transition")

  # Saves cursor state to localStorage when page changes
  saveCursorState: ->
    cursorState = {
      circleX: @circleX
      circleY: @circleY
      dotX: @dotX
      dotY: @dotY
      targetX: @targetX
      targetY: @targetY
      isShrinking: @isShrinking
      isMouseInWindow: @isMouseInWindow
      timestamp: Date.now()
    }
    localStorage.setItem('cursorState', JSON.stringify(cursorState))

  # Loads cursor state from localStorage if available
  loadCursorState: ->
    cursorState = JSON.parse(localStorage.getItem('cursorState'))
    if cursorState
      # Use the saved position
      @circleX = cursorState.circleX
      @circleY = cursorState.circleY
      @targetX = cursorState.targetX
      @targetY = cursorState.targetY
      @dotX = @targetX - 8
      @dotY = @targetY - 8
      
      # Check if the state is recent (within 5 minutes)
      isRecent = (Date.now() - cursorState.timestamp) < 5 * 60 * 1000

      if isRecent
        @isShrinking = cursorState.isShrinking
        @isMouseInWindow = cursorState.isMouseInWindow ? true

        # Apply loaded positions immediately
        @circle?.style.setProperty("--translate-x", "#{@circleX}px")
        @circle?.style.setProperty("--translate-y", "#{@circleY}px")
        @dot?.style.setProperty("--translate-x", "#{@dotX}px")
        @dot?.style.setProperty("--translate-y", "#{@dotY}px")
      else
        # State is old, just load the shrink state and wait for mouse move
        @isShrinking = cursorState.isShrinking
        @isMouseInWindow = false

    # Apply shrinking state if needed
    if @isShrinking
      @circle?.classList.add("shrink")
    else
      @circle?.classList.remove("shrink")
      
    # Apply visibility based on mouse in window and reduced motion
    prefersReducedMotion = globalThis.matchMedia("(prefers-reduced-motion: reduce)").matches
    if @isMouseInWindow and not prefersReducedMotion
      @circle?.style.display = "block"
      @dot?.style.display = "block"
    else
      @circle?.style.display = "none"
      @dot?.style.display = "none"
      
    # Finish initialization if mouse is in window
    if @isMouseInWindow
      @finishInitialization()

  # Handles mouse movement by updating CSS variables for the circle's position.
  # @param {MouseEvent} event - The mousemove event object.
  handleMouseMove: (event) ->
    # Update the flag - user has moved mouse
    @hasUserMovedMouse = true
    
    prefersReducedMotion = globalThis.matchMedia("(prefers-reduced-motion: reduce)").matches
    if prefersReducedMotion or not @isMouseInWindow
      @circle?.style.display = "none"
      @dot?.style.display = "none"
      return
    else
      @circle?.style.display = "block"
      @dot?.style.display = "block"

    # Get current mouse position
    x = event.clientX
    y = event.clientY
    
    # If initializing, immediately finish initialization at current position
    if @isInitializing
      @targetX = x
      @targetY = y
      @circleX = x
      @circleY = y
      @dotX = x - 8
      @dotY = y - 8
      
      # Ensure no transition for initial positioning
      @circle?.classList.add("no-transition")
      @dot?.classList.add("no-transition")
      @finishInitialization()
    else
      # Normal behavior after initialization
      @targetX = x
      @targetY = y
      # Update dot position immediately (exact follow)
      @dotX = x - 8
      @dotY = y - 8
      @dot?.style.setProperty("--translate-x", "#{@dotX}px")
      @dot?.style.setProperty("--translate-y", "#{@dotY}px")

  # Animates the ring to follow the target position with easing.
  animateCursor: ->
    # Only animate if we're not initializing and have a mouse position
    if !@isInitializing
      # Only animate ring when cursor is visible (after initialization)
      deltaX = @targetX - @circleX
      deltaY = @targetY - @circleY
      distance = Math.hypot(deltaX, deltaY)
      threshold = 0.1

      if distance > threshold
        # Enable will-change when actively animating
        @circle?.style.setProperty("will-change", "transform")
        
        easingAmount = 0.2
        @circleX = lerp(@circleX, @targetX, easingAmount)
        @circleY = lerp(@circleY, @targetY, easingAmount)
        
        # Update ring position
        @circle?.style.setProperty("--translate-x", "#{@circleX}px")
        @circle?.style.setProperty("--translate-y", "#{@circleY}px")
      else
        # Static position - remove will-change optimization
        @circle?.style.setProperty("will-change", "auto")
        @circleX = @targetX
        @circleY = @targetY
        
        # Update ring position
        @circle?.style.setProperty("--translate-x", "#{@circleX}px")
        @circle?.style.setProperty("--translate-y", "#{@circleY}px")

    requestAnimationFrame(@animateCursor)

  # Handles mouse down events by adding the shrink class to the ring.
  handleMouseDown: (event) ->
    if event.button is 0 and @circle and not @isShrinking
      @isShrinking = true
      @circle.classList.add("shrink")

  # Handles mouse up events by removing the shrink class from the ring.
  handleMouseUp: (event) ->
    if event.button is 0 and @circle and @isShrinking
      @circle.classList.remove("shrink")
      @isShrinking = false
      
  # Handles mouse leave events by hiding the cursor elements.
  handleMouseLeave: (event) ->
    @isMouseInWindow = false
    @circle?.style.display = "none"
    @dot?.style.display = "none"
    
  # Handles mouse enter events by showing the cursor elements if appropriate.
  handleMouseEnter: (event) ->
    @isMouseInWindow = true
    prefersReducedMotion = globalThis.matchMedia("(prefers-reduced-motion: reduce)").matches
    if not prefersReducedMotion
      @circle?.style.display = "block"
      @dot?.style.display = "block"