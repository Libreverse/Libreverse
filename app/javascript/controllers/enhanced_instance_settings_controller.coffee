import { Controller } from "@hotwired/stimulus"
import { useStore } from "stimulus-store"
import { instanceSettingsStore, toastStore } from "../stores"
import StimulusReflex from "stimulus_reflex"

###
Enhanced Instance Settings Controller with stimulus-store integration
Manages instance configuration with centralized state and optimistic updates
###
export default class extends Controller
  @stores = [instanceSettingsStore, toastStore]

  @values = {
    # Auto-save configuration
    autoSave: { type: Boolean, default: true },
    autoSaveDelay: { type: Number, default: 1000 },
    # Validation
    validateOnChange: { type: Boolean, default: true },
  }

  connect: ->
    console.log "[EnhancedInstanceSettingsController] Connected"
    
    # Set up stimulus-store
    useStore(@)
    
    # Set up StimulusReflex
    if typeof StimulusReflex isnt 'undefined'
      StimulusReflex.register(@)
    
    # Initialize form state from current values
    @initializeFormState()
    
    # Set up auto-save timer
    @setupAutoSave()

  disconnect: ->
    console.log "[EnhancedInstanceSettingsController] Disconnecting"
    @cleanupAutoSave()

  # Initialize form state from DOM
  initializeFormState: ->
    currentSettings = @instanceSettingsStoreValue
    
    # Read current values from form elements
    formData = @getFormData()
    
    # Update store with current form values
    @instanceSettingsStoreValue = {
      ...currentSettings,
      ...formData,
      isDirty: false,
      isLoading: false
    }

  # Get current form data
  getFormData: ->
    formData = {}
    
    # Read checkbox states
    automoderationCheckbox = @element.querySelector("[data-action*='toggleAutomoderation']")
    formData.automoderation = automoderationCheckbox?.checked || false
    
    eeaModeCheckbox = @element.querySelector("[data-action*='toggleEeaMode']")
    formData.eeaMode = eeaModeCheckbox?.checked || false
    
    forceSslCheckbox = @element.querySelector("[data-action*='toggleForceSsl']")
    formData.forceSsl = forceSslCheckbox?.checked || false
    
    noSslCheckbox = @element.querySelector("[data-action*='toggleNoSsl']")
    formData.noSsl = noSslCheckbox?.checked || false
    
    # Read text inputs
    railsLogLevelInput = @element.querySelector("[data-action*='updateRailsLogLevel']")
    formData.railsLogLevel = railsLogLevelInput?.value || "info"
    
    allowedHostsInput = @element.querySelector("[data-action*='updateAllowedHosts']")
    formData.allowedHosts = allowedHostsInput?.value || ""
    
    corsOriginsInput = @element.querySelector("[data-action*='updateCorsOrigins']")
    formData.corsOrigins = corsOriginsInput?.value || ""
    
    portInput = @element.querySelector("[data-action*='updatePort']")
    formData.port = parseInt(portInput?.value) || 3000
    
    adminEmailInput = @element.querySelector("[data-action*='updateAdminEmail']")
    formData.adminEmail = adminEmailInput?.value || ""
    
    formData

  # Set up auto-save functionality
  setupAutoSave: ->
    return unless @autoSaveValue
    
    @autoSaveTimer = undefined
    
    # Set up store change listener for auto-save
    @instanceSettingsStoreChanged = @handleStoreChange.bind(@)
    @element.addEventListener("instanceSettingsStore:changed", @instanceSettingsStoreChanged)

  # Clean up auto-save
  cleanupAutoSave: ->
    if @autoSaveTimer
      clearTimeout(@autoSaveTimer)
    
    @element.removeEventListener("instanceSettingsStore:changed", @instanceSettingsStoreChanged) if @instanceSettingsStoreChanged

  # Handle store changes
  handleStoreChange: (event) ->
    settings = event.detail.value
    
    # Skip if not dirty or already loading
    return if not settings.isDirty or settings.isLoading
    
    # Clear existing timer
    if @autoSaveTimer
      clearTimeout(@autoSaveTimer)
    
    # Set new timer for auto-save
    @autoSaveTimer = setTimeout =>
      @saveSettings()
    , @autoSaveDelayValue

  # Save settings to server
  saveSettings: ->
    settings = @instanceSettingsStoreValue
    
    # Mark as loading
    @instanceSettingsStoreValue = { ...settings, isLoading: true }
    
    # Save all settings at once
    @stimulate('InstanceSettings#save_all_settings', {
      automoderation: settings.automoderation,
      eeaMode: settings.eeaMode,
      forceSsl: settings.forceSsl,
      noSsl: settings.noSsl,
      railsLogLevel: settings.railsLogLevel,
      allowedHosts: settings.allowedHosts,
      corsOrigins: settings.corsOrigins,
      port: settings.port,
      adminEmail: settings.adminEmail
    })

  # Handle successful save
  handleSaveSuccess: ->
    settings = @instanceSettingsStoreValue
    @instanceSettingsStoreValue = {
      ...settings,
      isDirty: false,
      isLoading: false
    }
    
    @showToast("Settings saved successfully", "success")

  # Handle save error
  handleSaveError: (error) ->
    settings = @instanceSettingsStoreValue
    @instanceSettingsStoreValue = {
      ...settings,
      isLoading: false
    }
    
    @showToast("Failed to save settings: #{error}", "error")

  # Toggle methods with optimistic updates
  toggleAutomoderation: (event) ->
    event.preventDefault()
    
    settings = @instanceSettingsStoreValue
    newValue = not settings.automoderation
    
    # Optimistic update
    @instanceSettingsStoreValue = {
      ...settings,
      automoderation: newValue,
      isDirty: true
    }
    
    # Update UI immediately
    @updateCheckbox(event.target, newValue)
    
    # Save if not auto-saving
    unless @autoSaveValue
      @stimulate('InstanceSettings#toggle_automoderation')

  toggleEeaMode: (event) ->
    event.preventDefault()
    
    settings = @instanceSettingsStoreValue
    newValue = not settings.eeaMode
    
    # Optimistic update
    @instanceSettingsStoreValue = {
      ...settings,
      eeaMode: newValue,
      isDirty: true
    }
    
    # Update UI immediately
    @updateCheckbox(event.target, newValue)
    
    # Save if not auto-saving
    unless @autoSaveValue
      @stimulate('InstanceSettings#toggle_eea_mode')

  toggleForceSsl: (event) ->
    event.preventDefault()
    
    settings = @instanceSettingsStoreValue
    newValue = not settings.forceSsl
    
    # Optimistic update
    @instanceSettingsStoreValue = {
      ...settings,
      forceSsl: newValue,
      isDirty: true
    }
    
    # Validate SSL settings
    if newValue and settings.noSsl
      @showToast("Cannot enable Force SSL and No SSL simultaneously", "warning")
      return
    
    # Update UI immediately
    @updateCheckbox(event.target, newValue)
    
    # Save if not auto-saving
    unless @autoSaveValue
      @stimulate('InstanceSettings#toggle_force_ssl')

  toggleNoSsl: (event) ->
    event.preventDefault()
    
    settings = @instanceSettingsStoreValue
    newValue = not settings.noSsl
    
    # Optimistic update
    @instanceSettingsStoreValue = {
      ...settings,
      noSsl: newValue,
      isDirty: true
    }
    
    # Validate SSL settings
    if newValue and settings.forceSsl
      @showToast("Cannot enable No SSL and Force SSL simultaneously", "warning")
      return
    
    # Update UI immediately
    @updateCheckbox(event.target, newValue)
    
    # Save if not auto-saving
    unless @autoSaveValue
      @stimulate('InstanceSettings#toggle_no_ssl')

  # Update methods with validation
  updateRailsLogLevel: (event) ->
    value = event.target.value
    
    # Validate log level
    validLevels = ["debug", "info", "warn", "error", "fatal"]
    unless validLevels.includes(value)
      @showToast("Invalid log level", "error")
      return
    
    settings = @instanceSettingsStoreValue
    @instanceSettingsStoreValue = {
      ...settings,
      railsLogLevel: value,
      isDirty: true
    }
    
    # Save if not auto-saving
    unless @autoSaveValue
      @stimulate('InstanceSettings#update_rails_log_level', value)

  updateAllowedHosts: (event) ->
    value = event.target.value
    
    # Basic validation for host format
    if @validateOnChangeValue and value and not @isValidHostList(value)
      @showToast("Invalid host format", "warning")
      return
    
    settings = @instanceSettingsStoreValue
    @instanceSettingsStoreValue = {
      ...settings,
      allowedHosts: value,
      isDirty: true
    }
    
    # Save if not auto-saving
    unless @autoSaveValue
      @stimulate('InstanceSettings#update_allowed_hosts', value)

  updateCorsOrigins: (event) ->
    value = event.target.value
    
    # Basic validation for CORS origins
    if @validateOnChangeValue and value and not @isValidCorsOrigins(value)
      @showToast("Invalid CORS origins format", "warning")
      return
    
    settings = @instanceSettingsStoreValue
    @instanceSettingsStoreValue = {
      ...settings,
      corsOrigins: value,
      isDirty: true
    }
    
    # Save if not auto-saving
    unless @autoSaveValue
      @stimulate('InstanceSettings#update_cors_origins', value)

  updatePort: (event) ->
    value = parseInt(event.target.value)
    
    # Validate port number
    if isNaN(value) or value < 1 or value > 65535
      @showToast("Port must be between 1 and 65535", "error")
      return
    
    settings = @instanceSettingsStoreValue
    @instanceSettingsStoreValue = {
      ...settings,
      port: value,
      isDirty: true
    }
    
    # Save if not auto-saving
    unless @autoSaveValue
      @stimulate('InstanceSettings#update_port', value)

  updateAdminEmail: (event) ->
    value = event.target.value
    
    # Basic email validation
    if @validateOnChangeValue and value and not @isValidEmail(value)
      @showToast("Invalid email format", "warning")
      return
    
    settings = @instanceSettingsStoreValue
    @instanceSettingsStoreValue = {
      ...settings,
      adminEmail: value,
      isDirty: true
    }
    
    # Save if not auto-saving
    unless @autoSaveValue
      @stimulate('InstanceSettings#update_admin_email', value)

  # Utility methods
  updateCheckbox: (checkbox, value) ->
    checkbox.checked = value
    checkbox.setAttribute("aria-checked", value.toString())

  isValidEmail: (email) ->
    /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)

  isValidHostList: (hosts) ->
    # Basic validation - should be comma-separated hostnames or IPs
    hostList = hosts.split(",").map((h) -> h.trim())
    hostList.every (host) ->
      /^[a-zA-Z0-9.-]+$/.test(host) or /^(\d{1,3}\.){3}\d{1,3}$/.test(host)

  isValidCorsOrigins: (origins) ->
    # Basic validation for CORS origins
    originList = origins.split(",").map((o) -> o.trim())
    originList.every (origin) ->
      origin is "*" or /^https?:\/\/[a-zA-Z0-9.-]+(:\d+)?$/.test(origin)

  showToast: (message, type = "info") ->
    currentToasts = @toastStoreValue
    newToast = {
      id: currentToasts.nextId,
      message,
      type,
      timeout: currentToasts.defaultTimeout,
      timestamp: Date.now()
    }
    
    # Add toast to store
    updatedToasts = [...currentToasts.toasts, newToast]
    if updatedToasts.length > currentToasts.maxToasts
      updatedToasts = updatedToasts.slice(-currentToasts.maxToasts)
    
    @toastStoreValue = {
      ...currentToasts,
      toasts: updatedToasts,
      nextId: currentToasts.nextId + 1
    }

  # Public methods for external access
  getCurrentSettings: ->
    @instanceSettingsStoreValue

  isDirty: ->
    @instanceSettingsStoreValue.isDirty

  isLoading: ->
    @instanceSettingsStoreValue.isLoading

  resetToDefaults: ->
    @instanceSettingsStoreValue = {
      automoderation: false,
      eeaMode: false,
      forceSsl: false,
      noSsl: false,
      railsLogLevel: "info",
      allowedHosts: "",
      corsOrigins: "",
      port: 3000,
      adminEmail: "",
      isDirty: true,
      isLoading: false
    }
    
    # Update form fields
    @updateFormFromStore()

  updateFormFromStore: ->
    settings = @instanceSettingsStoreValue
    
    # Update checkboxes
    @element.querySelector("[data-action*='toggleAutomoderation']")?.checked = settings.automoderation
    @element.querySelector("[data-action*='toggleEeaMode']")?.checked = settings.eeaMode
    @element.querySelector("[data-action*='toggleForceSsl']")?.checked = settings.forceSsl
    @element.querySelector("[data-action*='toggleNoSsl']")?.checked = settings.noSsl
    
    # Update text inputs
    railsLogLevelInput = @element.querySelector("[data-action*='updateRailsLogLevel']")
    railsLogLevelInput.value = settings.railsLogLevel if railsLogLevelInput
    
    allowedHostsInput = @element.querySelector("[data-action*='updateAllowedHosts']")
    allowedHostsInput.value = settings.allowedHosts if allowedHostsInput
    
    corsOriginsInput = @element.querySelector("[data-action*='updateCorsOrigins']")
    corsOriginsInput.value = settings.corsOrigins if corsOriginsInput
    
    portInput = @element.querySelector("[data-action*='updatePort']")
    portInput.value = settings.port if portInput
    
    adminEmailInput = @element.querySelector("[data-action*='updateAdminEmail']")
    adminEmailInput.value = settings.adminEmail if adminEmailInput
