import { Controller } from "@hotwired/stimulus"
import { useStore } from "stimulus-store"
import { toastStore } from "../stores"

###
Enhanced Toast Controller with stimulus-store integration
Manages individual toast notifications with centralized state
###
export default class extends Controller
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
    console.log "[EnhancedToastController] Connected, ID:", @toastIdValue
    
    # Set up stimulus-store
    useStore(@)
    
    # Initialize toast state
    @initializeToast()
    
    # Set up event listeners
    @setupEventListeners()
    
    # Start toast lifecycle
    @startToastLifecycle()

  disconnect: ->
    console.log "[EnhancedToastController] Disconnecting, ID:", @toastIdValue
    
    # Clean up timers and listeners
    @cleanupToast()
    
    # Remove from store
    @removeFromStore()

  initializeToast: ->
    # Get or create toast data in store
    currentToasts = @toastStoreValue
    
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
    
    # Store change listener
    @toastStoreChanged = @handleStoreChange.bind(@)
    @element.addEventListener("toastStore:changed", @toastStoreChanged)

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
    @element.removeEventListener("toastStore:changed", @toastStoreChanged) if @toastStoreChanged

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
      
      @updateToastInStore({ progress: progress * 100 })
      
      if progress >= 1
        clearInterval(@progressInterval)
    , 50

  # Event handlers
  handleMouseEnter: ->
    @pauseToast()

  handleMouseLeave: ->
    @resumeToast()

  handleClick: (event) ->
    # Dismiss on click unless it's a button or link
    unless event.target.matches("button, a, [role='button']")
      @dismiss()

  handleKeydown: (event) ->
    if event.key is "Escape"
      @dismiss()

  handleStoreChange: (event) ->
    toasts = event.detail.value.toasts
    currentToast = toasts.find((t) => t.id is @toastIdValue)
    
    # If toast was removed from store, dismiss immediately
    unless currentToast
      @dismiss(false) # Don't update store again

  # Toast control methods
  pauseToast: ->
    return unless @dismissTimer
    
    # Pause dismiss timer
    @remainingTime = @timeoutValue - (Date.now() - @timerStartTime)
    clearTimeout(@dismissTimer)
    
    # Pause progress animation
    if @progressBar
      @progressBar.style.animationPlayState = "paused"
    
    # Update store
    @updateToastInStore({ isPaused: true })

  resumeToast: ->
    return unless @remainingTime
    
    # Resume dismiss timer
    @timerStartTime = Date.now()
    @dismissTimer = setTimeout =>
      @dismiss()
    , @remainingTime
    
    # Resume progress animation
    if @progressBar
      @progressBar.style.animationPlayState = "running"
    
    # Update store
    @updateToastInStore({ isPaused: false })

  dismiss: (updateStore = true) ->
    # Prevent multiple dismiss calls
    return if @isDismissing
    @isDismissing = true
    
    # Clean up timers
    @cleanupToast()
    
    # Update store first if needed
    if updateStore
      @removeFromStore()
    
    # Animate out
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

  # Store management
  updateToastInStore: (updates) ->
    currentToasts = @toastStoreValue
    
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
    currentToasts = @toastStoreValue
    
    @toastStoreValue = {
      ...currentToasts,
      toasts: currentToasts.toasts.filter((toast) => toast.id isnt @toastIdValue)
    }

  # Public API
  getToastData: ->
    currentToasts = @toastStoreValue
    currentToasts.toasts.find((t) => t.id is @toastIdValue)

  updateMessage: (newMessage) ->
    @messageValue = newMessage
    @updateToastInStore({ message: newMessage })
    
    # Update DOM
    messageElement = @element.querySelector(".toast-message")
    if messageElement
      messageElement.textContent = newMessage
    else
      @element.textContent = newMessage

  updateType: (newType) ->
    # Remove old type class
    @element.classList.remove("toast-#{@typeValue}")
    
    # Update value and add new class
    @typeValue = newType
    @element.classList.add("toast-#{newType}")
    
    # Update store
    @updateToastInStore({ type: newType })

  extendTimeout: (additionalTime) ->
    @timeoutValue += additionalTime
    @updateToastInStore({ timeout: @timeoutValue })
    
    # Reset timer if active
    if @dismissTimer
      clearTimeout(@dismissTimer)
      @startDismissTimer()

  # Static methods for creating toasts programmatically
  @createToast: (message, type = "info", options = {}) ->
    container = document.querySelector(".toast-container") or @createToastContainer()
    
    toastElement = document.createElement("div")
    toastElement.className = "toast"
    toastElement.setAttribute("data-controller", "enhanced-toast")
    toastElement.setAttribute("data-enhanced-toast-message-value", message)
    toastElement.setAttribute("data-enhanced-toast-type-value", type)
    toastElement.setAttribute("data-enhanced-toast-toast-id-value", Date.now())
    
    # Set options
    for key, value of options
      toastElement.setAttribute("data-enhanced-toast-#{key.replace(/([A-Z])/g, '-$1').toLowerCase()}-value", value)
    
    toastElement.innerHTML = """
      <div class="toast-content">
        <div class="toast-message">#{message}</div>
        <button class="toast-close" aria-label="Close">&times;</button>
      </div>
    """
    
    container.appendChild(toastElement)
    
    toastElement

  @createToastContainer: ->
    container = document.createElement("div")
    container.className = "toast-container"
    container.style.cssText = """
      position: fixed;
      top: 20px;
      right: 20px;
      z-index: 9999;
      display: flex;
      flex-direction: column;
      gap: 10px;
      max-width: 400px;
    """
    
    document.body.appendChild(container)
    container

  # Utility methods
  isDismissed: ->
    @isDismissing or not @element.parentNode

  getRemainingTime: ->
    if @remainingTime
      @remainingTime
    else if @dismissTimer
      @timeoutValue - (Date.now() - @timerStartTime)
    else
      0

  getProgress: ->
    toastData = @getToastData()
    toastData?.progress or 0
