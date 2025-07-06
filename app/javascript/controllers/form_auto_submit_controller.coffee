import ApplicationController from "./application_controller"

# Connects to data-controller="form-auto-submit"
export default class extends ApplicationController
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
    return

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
    return

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
    return if @isSubmitting
    
    # Clear existing timer
    if @debounceTimer
      clearTimeout(@debounceTimer)
    
    # Set up debounced validation
    @debounceTimer = setTimeout =>
      @validateForm()
    , @debounceTimeValue
    
    return

  handleInputBlur: (event) ->
    return if @isSubmitting
    
    # Clear debounce timer and validate immediately on blur
    if @debounceTimer
      clearTimeout(@debounceTimer)
    
    @validateField(event.target)
    return

  handleFormSubmit: (event) ->
    console.log("Form submit handler called", { isSubmitting: @isSubmitting, event: event })
    
    return if @isSubmitting
    
    # Validate invisible captcha timing if present
    if @hasInvisibleCaptcha() && !@validateInvisibleCaptchaTiming()
      console.warn("Form submission blocked: invisible captcha timing validation failed")
      event.preventDefault()
      return
    
    # Validate entire form
    isValid = @performClientValidation()
    console.log("Client validation result:", isValid, "Errors:", @validationErrors)
    
    if !isValid
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
    
    return

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

    return

  validateField: (field) ->
    return unless field

    # Clear previous field errors
    @hideFieldError(field)

    # Validate the specific field
    isValid = @validateSingleField(field)

    if !isValid
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
      isValid = isValid && fieldValid

    return isValid

  validateSingleField: (field) ->
    return true unless field

    fieldName = field.name?.toLowerCase() || ""
    fieldType = field.type?.toLowerCase() || ""
    value = field.value?.toString() || ""

    # Check required fields
    if field.hasAttribute('required') && value.trim().length == 0
      @addFieldError(field, "This field is required")
      return false

    # Validate email fields
    if (fieldType == 'email' || fieldName.includes('email')) && value.trim().length > 0
      emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
      if !emailRegex.test(value.trim())
        @addFieldError(field, "Please enter a valid email address")
        return false

    # Validate password fields
    if fieldType == 'password' && !fieldName.includes('confirmation')
      if value.length > 0 && value.length < @minPasswordLengthValue
        @addFieldError(field, "Password must be at least #{@minPasswordLengthValue} characters long")
        return false

    # Validate password confirmation
    if fieldName.includes('confirmation') && fieldType == 'password'
      passwordField = @formTarget.querySelector('input[type="password"]:not([name*="confirmation"])')
      if passwordField && value != passwordField.value
        @addFieldError(field, "Password confirmation does not match")
        return false

    # Validate username fields
    if fieldName.includes('username') || fieldName.includes('login')
      if value.trim().length > 0
        if value.trim().length < 2 || value.trim().length > 50
          @addFieldError(field, "Username must be between 2 and 50 characters")
          return false
        if /\s/.test(value.trim())
          @addFieldError(field, "Username cannot contain spaces")
          return false

    return true

  addFieldError: (field, message) ->
    # Store error for form-level display
    @validationErrors.push(message)

  getFieldErrors: (field) ->
    # Return specific errors for this field
    fieldName = field.name?.toLowerCase() || ""
    fieldType = field.type?.toLowerCase() || ""
    value = field.value?.toString() || ""
    errors = []

    if field.hasAttribute('required') && value.trim().length == 0
      errors.push("This field is required")

    if (fieldType == 'email' || fieldName.includes('email')) && value.trim().length > 0
      emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
      if !emailRegex.test(value.trim())
        errors.push("Please enter a valid email address")

    if fieldType == 'password' && !fieldName.includes('confirmation')
      if value.length > 0 && value.length < @minPasswordLengthValue
        errors.push("Password must be at least #{@minPasswordLengthValue} characters long")

    if fieldName.includes('confirmation') && fieldType == 'password'
      passwordField = @formTarget.querySelector('input[type="password"]:not([name*="confirmation"])')
      if passwordField && value != passwordField.value
        errors.push("Password confirmation does not match")

    if fieldName.includes('username') || fieldName.includes('login')
      if value.trim().length > 0
        if value.trim().length < 2 || value.trim().length > 50
          errors.push("Username must be between 2 and 50 characters")
        if /\s/.test(value.trim())
          errors.push("Username cannot contain spaces")

    return errors

  showFieldError: (field, message) ->
    # Add error class to field
    field.classList.add('is-invalid')
    field.classList.remove('is-valid')
    
    # Find or create error message element
    errorId = "#{field.id || field.name}_error"
    errorElement = document.getElementById(errorId)
    
    if !errorElement
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
    
    return

  hideFieldError: (field) ->
    # Remove error classes
    field.classList.remove('is-invalid')
    field.classList.add('is-valid')
    
    # Hide error message
    errorId = "#{field.id || field.name}_error"
    errorElement = document.getElementById(errorId)
    
    if errorElement
      errorElement.style.display = 'none'
      errorElement.textContent = ''
    
    # Remove aria attributes
    field.removeAttribute('aria-describedby')
    field.removeAttribute('aria-invalid')
    
    return

  showFormErrors: ->
    errorContainer = document.getElementById('form-errors')
    return unless errorContainer
    
    if @validationErrors.length > 0
      errorHtml = """
        <h3>Please fix the following errors:</h3>
        <ul>
          #{@validationErrors.map((error) -> "<li>#{error}</li>").join('')}
        </ul>
      """
      
      errorContainer.innerHTML = errorHtml
      errorContainer.style.display = 'block'
      
      # Scroll to errors
      errorContainer.scrollIntoView({ behavior: 'smooth', block: 'center' })
    
    return

  clearAllErrors: ->
    # Clear form-level errors
    errorContainer = document.getElementById('form-errors')
    if errorContainer
      errorContainer.innerHTML = ''
      errorContainer.style.display = 'none'
    
    # Clear field-level errors
    @inputTargets.forEach (field) =>
      @hideFieldError(field)
    
    return

  # Legacy method for backward compatibility
  onFormValidated: ->
    # This method can be removed as we're no longer using StimulusReflex
    # But keeping it for any existing code that might reference it
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
