import ApplicationController from "./application_controller"
import { toastStore } from "../stores"

# Toast Controller with stimulus-store integration
# This controller is attached directly to individual toast elements.
# It handles auto-hiding, manual dismissal, and centralized toast management.
export default class extends ApplicationController
  @stores = [toastStore]

  @values = {
    toastId: { type: Number, default: 0 },
    timeout: { type: Number, default: 5000 },
    type: { type: String, default: "info" },
    message: { type: String, default: "" },
    # Animation settings
    slideDirection: { type: String, default: "up" }, # "up", "down", "left", "right"
    animationDuration: { type: Number, default: 300 },
    # Auto-dismiss settings
    pauseOnHover: { type: Boolean, default: true },
    showProgress: { type: Boolean, default: false },
  }

  connect: ->
    console.log "[ToastController] Connected, ID:", @toastIdValue

    # Call parent connect (sets up StimulusReflex and stores)
    super()

    # Ensure toast store is properly initialized
    @ensureToastStoreInitialized()

    # Initialize toast state
    @initializeToast()

    # Set up event listeners
    @setupEventListeners()

    # Start toast lifecycle
    @startToastLifecycle()

  ensureToastStoreInitialized: ->
    # Check if store value exists, if not initialize it
    if not @toastStoreValue or not @toastStoreValue.toasts
      @toastStoreValue = {
        toasts: [],
        nextId: 1,
        defaultTimeout: 5000,
        maxToasts: 5
      }

  disconnect: ->
    console.log "[ToastController] Disconnecting, ID:", @toastIdValue

    # Clean up timers and listeners
    @cleanupToast()

    # Remove from store
    @removeFromStore()

    # Call parent disconnect
    super()

  initializeToast: ->
    # Get or create toast data in store
    currentToasts = @toastStoreValue or { toasts: [], nextId: 1, defaultTimeout: 5000, maxToasts: 5 }

    # Ensure toasts array exists
    if not currentToasts.toasts
      currentToasts.toasts = []

    # Find existing toast or create new one
    existingToast = currentToasts.toasts.find((t) => t.id is @toastIdValue)

    if not existingToast
      # Create new toast entry
      newToast = {
        id: @toastIdValue,
        message: @messageValue,
        type: @typeValue,
        timeout: @timeoutValue,
        timestamp: Date.now(),
        isVisible: false,
        isPaused: false,
        progress: 0
      }

      @toastStoreValue = {
        ...currentToasts,
        toasts: [...currentToasts.toasts, newToast]
      }

    # Set up initial styling
    @setupInitialStyling()

  setupInitialStyling: ->
    # Set initial opacity and transform for animation
    @element.style.opacity = "0"
    @element.style.transition = "opacity #{@animationDurationValue}ms ease-in-out, transform #{@animationDurationValue}ms ease-in-out"

    # Set initial transform based on slide direction
    switch @slideDirectionValue
      when "up"
        @element.style.transform = "translateY(10px)"
      when "down"
        @element.style.transform = "translateY(-10px)"
      when "left"
        @element.style.transform = "translateX(10px)"
      when "right"
        @element.style.transform = "translateX(-10px)"

    # Add type-specific classes
    @element.classList.add("toast-#{@typeValue}")

    # Add progress bar if enabled
    if @showProgressValue
      @createProgressBar()

  createProgressBar: ->
    @progressBar = document.createElement("div")
    @progressBar.className = "toast-progress"
    @progressBar.style.cssText = """
      position: absolute;
      bottom: 0;
      left: 0;
      height: 3px;
      background: currentColor;
      opacity: 0.6;
      transition: width #{@timeoutValue}ms linear;
      width: 0%;
    """

    @element.appendChild(@progressBar)

  setupEventListeners: ->
    if @pauseOnHoverValue
      @element.addEventListener("mouseenter", @handleMouseEnter.bind(@))
      @element.addEventListener("mouseleave", @handleMouseLeave.bind(@))

    # Click to dismiss
    @element.addEventListener("click", @handleClick.bind(@))

    # Keyboard support
    @element.addEventListener("keydown", @handleKeydown.bind(@))

  cleanupToast: ->
    # Clear timers
    if @dismissTimer
      clearTimeout(@dismissTimer)
      @dismissTimer = undefined

    if @progressInterval
      clearInterval(@progressInterval)
      @progressInterval = undefined

    # Remove event listeners
    @element.removeEventListener("mouseenter", @handleMouseEnter) if @handleMouseEnter
    @element.removeEventListener("mouseleave", @handleMouseLeave) if @handleMouseLeave
    @element.removeEventListener("click", @handleClick) if @handleClick
    @element.removeEventListener("keydown", @handleKeydown) if @handleKeydown

  startToastLifecycle: ->
    # Show toast with animation
    requestAnimationFrame =>
      @showToast()

      # Start auto-dismiss timer if timeout is set
      if @timeoutValue > 0
        @startDismissTimer()

      # Start progress animation
      if @showProgressValue
        @startProgressAnimation()

  showToast: ->
    # Update store
    @updateToastInStore({ isVisible: true })

    # Animate in
    @element.style.opacity = "1"
    @element.style.transform = "translateY(0) translateX(0)"

    # Focus for accessibility
    @element.setAttribute("tabindex", "0")
    @element.focus()

  startDismissTimer: ->
    @dismissTimer = setTimeout =>
      @dismiss()
    , @timeoutValue

  startProgressAnimation: ->
    return unless @progressBar

    # Start progress bar animation
    requestAnimationFrame =>
      @progressBar.style.width = "100%"

    # Update progress in store
    @progressStartTime = Date.now()
    @progressInterval = setInterval =>
      elapsed = Date.now() - @progressStartTime
      progress = Math.min(elapsed / @timeoutValue, 1)
      progressPercent = progress * 100

      @updateToastInStore({ progress: progressPercent })

      if progress >= 1
        clearInterval(@progressInterval)
    , 50

  # Event handlers
  handleMouseEnter: ->
    @pauseToast()

  handleMouseLeave: ->
    @resumeToast()

  handleClick: ->
    @dismiss()

  handleKeydown: (event) ->
    if event.key is "Escape" or event.key is "Enter" or event.key is " "
      event.preventDefault()
      @dismiss()

  # Toast lifecycle methods
  pauseToast: ->
    return if @isPaused

    @isPaused = true
    @updateToastInStore({ isPaused: true })

    # Pause timers
    if @dismissTimer
      clearTimeout(@dismissTimer)
      @dismissTimer = undefined

    if @progressInterval
      clearInterval(@progressInterval)
      @progressInterval = undefined

    # Pause progress bar animation
    if @progressBar
      @progressBar.style.animationPlayState = "paused"

  resumeToast: ->
    return unless @isPaused

    @isPaused = false
    @updateToastInStore({ isPaused: false })

    # Calculate remaining time
    elapsed = Date.now() - @progressStartTime
    remainingTime = Math.max(@timeoutValue - elapsed, 0)

    if remainingTime > 0
      @startDismissTimer()

      if @showProgressValue and @progressBar
        @progressBar.style.animationPlayState = "running"

  dismiss: ->
    # Prevent multiple dismiss calls
    return if @isDismissing
    @isDismissing = true

    console.log "[ToastController] Dismissing toast:", @toastIdValue

    # Update store
    @updateToastInStore({ isVisible: false })

    # Clear any timers
    @cleanupToast()

    # Trigger fade-out animation
    @element.style.opacity = "0"

    # Set exit transform based on slide direction
    switch @slideDirectionValue
      when "up"
        @element.style.transform = "translateY(-10px)"
      when "down"
        @element.style.transform = "translateY(10px)"
      when "left"
        @element.style.transform = "translateX(-10px)"
      when "right"
        @element.style.transform = "translateX(10px)"

    # Remove element after animation
    setTimeout =>
      @element.remove()
    , @animationDurationValue

  # Store management methods
  updateToastInStore: (updates) ->
    return unless @toastIdValue

    currentToasts = @toastStoreValue or { toasts: [], nextId: 1, defaultTimeout: 5000, maxToasts: 5 }

    # Ensure toasts array exists
    if not currentToasts.toasts
      currentToasts.toasts = []

    updatedToasts = currentToasts.toasts.map (toast) =>
      if toast.id is @toastIdValue
        { ...toast, ...updates }
      else
        toast

    @toastStoreValue = {
      ...currentToasts,
      toasts: updatedToasts
    }

  removeFromStore: ->
    return unless @toastIdValue

    currentToasts = @toastStoreValue or { toasts: [], nextId: 1, defaultTimeout: 5000, maxToasts: 5 }

    # Ensure toasts array exists
    if not currentToasts.toasts
      currentToasts.toasts = []

    @toastStoreValue = {
      ...currentToasts,
      toasts: currentToasts.toasts.filter((toast) => toast.id isnt @toastIdValue)
    }
