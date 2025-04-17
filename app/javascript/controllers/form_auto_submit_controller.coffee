import ApplicationController from "./application_controller"

# Connects to data-controller="form-auto-submit"
export default class extends ApplicationController
  @targets = ["form", "input"]
  @values = {
    debounceTime: { type: Number, default: 800 } # Default to 800ms debounce time
  }

  initialize: ->
    @timer = null
    @isSubmitting = false
    # Arrow function to maintain `this` context in the event listener
    @onFormValidated = @onFormValidated.bind(@)
    return

  connect: ->
    super.connect() # Call parent connect() to register StimulusReflex
    # StimulusReflex.register(@) # Handled by ApplicationController

    # Set up the form
    if @hasFormTarget
      # Add data attributes for StimulusReflex
      @formTarget.setAttribute("data-reflex-serialize-form", "true")

      # Ensure form has an ID
      unless @formTarget.id
        @formTarget.id = "form-#{Math.random().toString(36).substring(2, 10)}"

      # Create error container if needed
      @ensureErrorContainer()

      # Listen for the validated event
      @formTarget.addEventListener(
        "form:validated",
        @onFormValidated
      )

    # Monitor input changes
    @inputTargets.forEach (input) =>
      input.addEventListener("input", @handleInputChange.bind(@))
    return

  disconnect: ->
    # Clean up event listeners
    if @hasFormTarget
      @formTarget.removeEventListener(
        "form:validated",
        @onFormValidated
      )

    # Clear any pending timers
    if @timer
      clearTimeout @timer
      @timer = null
    return

  # Create error container if needed
  ensureErrorContainer: ->
    unless document.getElementById("form-errors")
      errorDiv = document.createElement("div")
      errorDiv.id = "form-errors"
      errorDiv.className = "form-errors"

      if @hasFormTarget
        @formTarget.parentNode.insertBefore(
          errorDiv,
          @formTarget
        )
    return

  handleInputChange: ->
    # Clear any existing timer
    if @timer
      clearTimeout @timer

    # Set a new timer for debounced validation
    @timer = setTimeout(
      (=> @validateForm()), # Use fat arrow for context
      @debounceTimeValue
    )
    return

  validateForm: ->
    return if @isSubmitting

    # Let the server handle validation
    @stimulate "FormReflex#submit"
    return

  # Arrow function defined in initialize ensures `this` context
  onFormValidated: ->
    # Prevent double submission
    return if @isSubmitting
    @isSubmitting = true

    # Submit the form
    setTimeout (=> # Use fat arrow for context
      # Submit the form, with fallback for older browsers
      if typeof @formTarget.requestSubmit == "function"
        @formTarget.requestSubmit()
      else
        @formTarget.submit()

      # Reset submission state after a delay
      setTimeout (=> @isSubmitting = false), 1000 # Use fat arrow for context
    ), 100
    return