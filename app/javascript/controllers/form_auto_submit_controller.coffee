ApplicationController = require './application_controller'
# Connects to data-controller="form-auto-submit"
class DefaultExport extends ApplicationController
  @targets = ["form", "input"]
  @values = {
    debounceTime: { type: Number, default: 800 },
    minPasswordLength: { type: Number, default: 12 },
    minTimestamp: { type: Number, default: 2 }
  }

  initialize: ->
    @isSubmitting = false
    @debounceTimer = null
    @validationErrors = []
    @boundHandleFormSubmit = @handleFormSubmit.bind(@)
    @boundHandleInputChange = @handleInputChange.bind(@)
    @boundHandleInputBlur = @handleInputBlur.bind(@)


  connect: ->
    super.connect()

    # Set up the form
    if @hasFormTarget
      console.log("Setting up form:", @formTarget, "Action:", @formTarget.action, "Method:", @formTarget.method)

      # Ensure form has an ID
      unless @formTarget.id
        @formTarget.id = "form-#{Math.random().toString(36).substring(2, 10)}"

      # Create error container if needed
      @ensureErrorContainer()

      # Set up form submit handler
      @formTarget.addEventListener("submit", @boundHandleFormSubmit)
      console.log("Form submit handler attached")

    # Monitor input changes with debounced validation
    @inputTargets.forEach (input) =>
      input.addEventListener("input", @boundHandleInputChange)
      input.addEventListener("blur", @boundHandleInputBlur)

    console.log("FormAutoSubmitController connected with", @inputTargets.length, "input targets")


  disconnect: ->
    # Clean up event listeners and timers
    if @debounceTimer
      clearTimeout(@debounceTimer)

    if @hasFormTarget
      @formTarget.removeEventListener("submit", @boundHandleFormSubmit)

    # Clean up input event listeners
    @inputTargets.forEach (input) =>
      input.removeEventListener("input", @boundHandleInputChange)
      input.removeEventListener("blur", @boundHandleInputBlur)

    super.disconnect()


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


  handleInputChange: ->
    return if @isSubmitting

    # Clear existing timer
    if @debounceTimer
      clearTimeout(@debounceTimer)

    # Set up debounced validation
    @debounceTimer = setTimeout =>
      @validateForm()
    , @debounceTimeValue


  handleInputBlur: (event) ->
    return if @isSubmitting

    # Clear debounce timer and validate immediately on blur
    if @debounceTimer
      clearTimeout(@debounceTimer)

    @validateField(event.target)


  handleFormSubmit: (event) ->
    console.log("Form submit handler called", { event })

    return if @isSubmitting

    # Validate invisible captcha timing if present
    if @hasInvisibleCaptcha() and not @validateInvisibleCaptchaTiming()
      console.warn("Form submission blocked: invisible captcha timing validation failed")
      event.preventDefault()
      return

    # Validate entire form
    isValid = @performClientValidation()
    console.log("Client validation result:", isValid, "Errors:", @validationErrors)

    if not isValid
      console.log("Form validation failed, preventing submission")
      event.preventDefault()
      @showFormErrors()
      return

    # If we get here, validation passed - allow normal form submission
    console.log("Form validation passed, allowing submission")
    @isSubmitting = true
    @formTarget.classList.add('submitting')

    # Reset submission state after a delay
    setTimeout =>
      @isSubmitting = false
      @formTarget.classList.remove('submitting')
    , 1000


  validateForm: ->
    return if @isSubmitting

    # Client-side validation
    isValid = @performClientValidation()

    if isValid
      @clearAllErrors()
      # For auto-submit functionality, submit the form when validation passes
      @autoSubmitForm()
    else
      @showFormErrors()

    return isValid

  autoSubmitForm: ->
    return if @isSubmitting

    console.log("Auto-submitting form")
    @isSubmitting = true
    @formTarget.classList.add('submitting')

    # Submit the form programmatically
    setTimeout =>
      if typeof @formTarget.requestSubmit is "function"
        @formTarget.requestSubmit()
      else
        @formTarget.submit()

      # Reset submission state after a delay
      setTimeout =>
        @isSubmitting = false
        @formTarget.classList.remove('submitting')
      , 1000
    , 100


  validateField: (field) ->
    return unless field

    # Clear previous field errors
    @hideFieldError(field)

    # Validate the specific field
    isValid = @validateSingleField(field)

    if not isValid
      errors = @getFieldErrors(field)
      @showFieldError(field, errors[0]) if errors.length > 0

    return isValid

  performClientValidation: ->
    return false unless @hasFormTarget

    # Clear previous errors for this validation run
    @validationErrors = []
    isValid = true

    # Validate all input fields
    @inputTargets.forEach (input) =>
      fieldValid = @validateSingleField(input)
      isValid and= fieldValid

    return isValid

  validateSingleField: (field) ->
    return true unless field

    fieldName = field.name?.toLowerCase() or ""
    fieldType = field.type?.toLowerCase() or ""
    value = field.value?.toString() or ""

    # Check each validation type
    return false unless @validateRequiredField(field, value)
    return false unless @validateEmailField(field, fieldName, fieldType, value)
    return false unless @validatePasswordField(field, fieldName, fieldType, value)
    return false unless @validatePasswordConfirmation(field, fieldName, fieldType, value)
    return false unless @validateUsernameField(field, fieldName, value)

    return true

  validateRequiredField: (field, value) ->
    if field.hasAttribute('required') and value.trim().length is 0
      @addFieldError(field, "This field is required")
      return false
    return true

  validateEmailField: (field, fieldName, fieldType, value) ->
    if (fieldType is 'email' or fieldName.includes('email')) and value.trim().length > 0
      emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
      if not emailRegex.test(value.trim())
        @addFieldError(field, "Please enter a valid email address")
        return false
    return true

  validatePasswordField: (field, fieldName, fieldType, value) ->
    if fieldType is 'password' and not fieldName.includes('confirmation')
      if value.length > 0 and value.length < @minPasswordLengthValue
        @addFieldError(field, "Password must be at least #{@minPasswordLengthValue} characters long")
        return false
    return true

  validatePasswordConfirmation: (field, fieldName, fieldType, value) ->
    if fieldName.includes('confirmation') and fieldType is 'password'
      passwordField = @formTarget.querySelector('input[type="password"]:not([name*="confirmation"])')
      if passwordField and value isnt passwordField.value
        @addFieldError(field, "Password confirmation does not match")
        return false
    return true

  validateUsernameField: (field, fieldName, value) ->
    if fieldName.includes('username') or fieldName.includes('login')
      if value.trim().length > 0
        if value.trim().length < 2 or value.trim().length > 50
          @addFieldError(field, "Username must be between 2 and 50 characters")
          return false
        if (/\s/).test(value.trim())
          @addFieldError(field, "Username cannot contain spaces")
          return false
    return true

  addFieldError: (field, message) ->
    # Store error for form-level display
    @validationErrors.push(message)

  getFieldErrors: (field) ->
    # Return specific errors for this field
    errors = []
    fieldName = field.name?.toLowerCase() or ""
    fieldType = field.type?.toLowerCase() or ""
    value = field.value?.toString() or ""

    # Use the same validation methods for consistency
    errors.push("This field is required") if not @validateRequiredField(field, value)
    errors.push("Please enter a valid email address") if not @validateEmailField(field, fieldName, fieldType, value)
    errors.push("Password is too short") if not @validatePasswordField(field, fieldName, fieldType, value)
    errors.push("Password confirmation does not match") if not @validatePasswordConfirmation(field, fieldName, fieldType, value)
    errors.push("Username is invalid") if not @validateUsernameField(field, fieldName, value)

    return errors

  showFieldError: (field, message) ->
    # Add error class to field
    field.classList.add('is-invalid')
    field.classList.remove('is-valid')

    # Find or create error message element
    errorId = "#{field.id or field.name}_error"
    errorElement = document.getElementById(errorId)

    if not errorElement
      errorElement = document.createElement('span')
      errorElement.id = errorId
      errorElement.className = 'invalid-feedback'

      # Insert error element after the field
      field.parentNode.insertBefore(errorElement, field.nextSibling)

    errorElement.textContent = message
    errorElement.style.display = 'block'

    # Set aria-describedby for accessibility
    field.setAttribute('aria-describedby', errorId)
    field.setAttribute('aria-invalid', 'true')


  hideFieldError: (field) ->
    # Remove error classes
    field.classList.remove('is-invalid')
    field.classList.add('is-valid')

    # Hide error message
    errorId = "#{field.id or field.name}_error"
    errorElement = document.getElementById(errorId)

    if errorElement
      errorElement.style.display = 'none'
      errorElement.textContent = ''

    # Remove aria attributes
    field.removeAttribute('aria-describedby')
    field.removeAttribute('aria-invalid')


  showFormErrors: ->
    errorContainer = document.getElementById('form-errors')
    return unless errorContainer

    if @validationErrors.length > 0
      errorItems = @validationErrors.map((error) => "<li>#{error}</li>").join('')
      errorHtml = """
        <h3>Please fix the following errors:</h3>
        <ul>
          #{errorItems}
        </ul>
      """

      errorContainer.innerHTML = errorHtml
      errorContainer.style.display = 'block'

      # Scroll to errors
      errorContainer.scrollIntoView({ behavior: 'smooth', block: 'center' })


  clearAllErrors: ->
    # Clear form-level errors
    errorContainer = document.getElementById('form-errors')
    if errorContainer
      errorContainer.innerHTML = ''
      errorContainer.style.display = 'none'

    # Clear field-level errors
    @inputTargets.forEach (field) =>
      @hideFieldError(field)


  # Legacy method for backward compatibility
  onFormValidated: ->

    ###
    # This method can be removed as we're no longer using StimulusReflex
    # But keeping it for any existing code that might reference it
    ###


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

    timestamp = Number.parseInt(timestampField.value, 10)
    return true if isNaN(timestamp)

    currentTime = Math.floor(Date.now() / 1000)
    timeDiff = currentTime - timestamp

    # Require at least 2 seconds (configurable threshold)
    minThreshold = @data.get("minTimestamp") or 2

    return timeDiff >= minThreshold

module.exports = DefaultExport
