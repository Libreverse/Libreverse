import ApplicationController from "./application_controller"

# Connects to data-controller="form-auto-submit"
export default class extends ApplicationController
  @targets = ["form", "input"]
  @values = {
    debounceTime: { type: Number, default: 800 }
  }

  initialize: ->
    @timer = null
    @isSubmitting = false
    @onFormValidated = @onFormValidated.bind(@)
    return

  connect: ->
    super.connect()

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
      (=> @validateForm()),
      @debounceTimeValue
    )
    return

  validateForm: ->
    return if @isSubmitting

    # Let the server handle validation
    @stimulate "FormReflex#submit"
    return

  onFormValidated: ->
    # Prevent double submission
    return if @isSubmitting

    # Check if invisible captcha fields are present and validate timing
    if @hasInvisibleCaptcha()
      unless @validateInvisibleCaptchaTiming()
        console.warn("Form submission blocked: invisible captcha timing validation failed")
        return

    @isSubmitting = true

    # Submit the form
    setTimeout (=>
      # Submit the form, with fallback for older browsers
      if typeof @formTarget.requestSubmit is "function"
        @formTarget.requestSubmit()
      else
        @formTarget.submit()

      # Reset submission state after a delay
      setTimeout (=> @isSubmitting = false), 1000
    ), 100
    return

  # Check if form has invisible captcha fields
  hasInvisibleCaptcha: ->
    return false unless @hasFormTarget

    # Look for timestamp field
    timestampField = @formTarget.querySelector('input[name="invisible_captcha_timestamp"]')
    # Look for honeypot field (random hex name)
    honeypotField = @formTarget.querySelector('input[type="text"][name^=""][style*="display:none"], input[type="text"][name^=""][style*="visibility:hidden"]')

    return timestampField? or honeypotField?

  # Validate invisible captcha timing constraints
  validateInvisibleCaptchaTiming: ->
    return true unless @hasFormTarget

    timestampField = @formTarget.querySelector('input[name="invisible_captcha_timestamp"]')
    return true unless timestampField?.value

    timestamp = parseInt(timestampField.value, 10)
    return true if isNaN(timestamp)

    currentTime = Math.floor(Date.now() / 1000)
    timeDiff = currentTime - timestamp

    # Require at least 2 seconds (configurable threshold)
    minThreshold = @data.get("minTimestamp") or 2

    return timeDiff >= minThreshold
