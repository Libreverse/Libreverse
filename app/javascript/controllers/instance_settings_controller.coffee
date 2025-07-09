import ApplicationController from "./application_controller"
import { useStore } from "stimulus-store"
import { instanceSettingsStore, toastStore } from "../stores"

# Instance Settings Controller with stimulus-store integration
# Manages instance configuration with centralized state and optimistic updates
export default class extends ApplicationController
  @stores = [instanceSettingsStore, toastStore]

  @values = {
    # Auto-save configuration
    autoSave: { type: Boolean, default: true },
    autoSaveDelay: { type: Number, default: 1000 },
    # Validation
    validateOnChange: { type: Boolean, default: true },
  }

  connect: ->
    console.log "[InstanceSettingsController] Connected"

    # Call parent connect (sets up StimulusReflex and stores)
    super()

    # Initialize form state from current values
    @initializeFormState()

    # Set up auto-save timer
    @setupAutoSave()

  disconnect: ->
    console.log "[InstanceSettingsController] Disconnecting"
    @cleanupAutoSave()
    super()

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
    formData.automoderation = automoderationCheckbox?.checked or false

    eeaModeCheckbox = @element.querySelector("[data-action*='toggleEeaMode']")
    formData.eeaMode = eeaModeCheckbox?.checked or false

    forceSslCheckbox = @element.querySelector("[data-action*='toggleForceSsl']")
    formData.forceSsl = forceSslCheckbox?.checked or false

    noSslCheckbox = @element.querySelector("[data-action*='toggleNoSsl']")
    formData.noSsl = noSslCheckbox?.checked or false

    grpcCheckbox = @element.querySelector("[data-action*='toggleGrpc']")
    formData.grpc = grpcCheckbox?.checked or false

    # Read text inputs
    railsLogLevelInput = @element.querySelector("[data-action*='updateRailsLogLevel']")
    formData.railsLogLevel = railsLogLevelInput?.value or "info"

    allowedHostsInput = @element.querySelector("[data-action*='updateAllowedHosts']")
    formData.allowedHosts = allowedHostsInput?.value or ""

    corsOriginsInput = @element.querySelector("[data-action*='updateCorsOrigins']")
    formData.corsOrigins = corsOriginsInput?.value or ""

    portInput = @element.querySelector("[data-action*='updatePort']")
    formData.port = parseInt(portInput?.value, 10) or 3000

    adminEmailInput = @element.querySelector("[data-action*='updateAdminEmail']")
    formData.adminEmail = adminEmailInput?.value or ""

    formData

  # Set up auto-save functionality
  setupAutoSave: ->
    return unless @autoSaveValue

    @autoSaveTimer = undefined

    # Set up store change listener for auto-save
    @instanceSettingsStoreChanged = @handleStoreChange.bind(@)
    @element.addEventListener("instanceSettingsStore:changed", @instanceSettingsStoreChanged)

  cleanupAutoSave: ->
    if @autoSaveTimer
      clearTimeout(@autoSaveTimer)
      @autoSaveTimer = undefined

    if @instanceSettingsStoreChanged
      @element.removeEventListener("instanceSettingsStore:changed", @instanceSettingsStoreChanged)

  # Store change handler
  handleStoreChange: (event) ->
    settings = event.detail.value

    # Schedule auto-save if dirty and auto-save is enabled
    if settings.isDirty and @autoSaveValue
      @scheduleAutoSave()

    # Update UI state indicators
    @updateUIState(settings)

  scheduleAutoSave: ->
    # Clear existing timer
    if @autoSaveTimer
      clearTimeout(@autoSaveTimer)

    # Schedule new save
    @autoSaveTimer = setTimeout =>
      @performAutoSave()
    , @autoSaveDelayValue

  performAutoSave: ->
    settings = @instanceSettingsStoreValue

    # Skip if not dirty or already saving
    return unless settings.isDirty and not settings.isLoading

    console.log "[InstanceSettingsController] Performing auto-save"

    # Show saving state
    @showToast("Saving settings...", "info", 1000)

    # Mark as loading
    @instanceSettingsStoreValue = {
      ...settings,
      isLoading: true
    }

    # Simulate save operation (replace with actual save logic)
    setTimeout =>
      @instanceSettingsStoreValue = {
        ...@instanceSettingsStoreValue,
        isDirty: false,
        isLoading: false,
        lastSaved: Date.now()
      }

      @showToast("Settings saved", "success", 2000)
    , 500

  updateUIState: (settings) ->
    # Update dirty indicator
    dirtyIndicator = @element.querySelector(".settings-dirty-indicator")
    if dirtyIndicator
      dirtyIndicator.style.display = if settings.isDirty then "block" else "none"

    # Update loading indicator
    loadingIndicator = @element.querySelector(".settings-loading-indicator")
    if loadingIndicator
      loadingIndicator.style.display = if settings.isLoading then "block" else "none"

  # Mark settings as dirty when changed
  markDirty: (updates = {}) ->
    @instanceSettingsStoreValue = {
      ...@instanceSettingsStoreValue,
      ...updates,
      isDirty: true
    }

  # Original StimulusReflex methods with store integration
  toggleAutomoderation: (event) ->
    event.preventDefault()

    # Optimistically update store
    currentValue = @instanceSettingsStoreValue.automoderation
    @markDirty({ automoderation: not currentValue })

    # Trigger StimulusReflex
    @stimulate('InstanceSettings#toggle_automoderation')

  toggleEeaMode: (event) ->
    event.preventDefault()

    # Optimistically update store
    currentValue = @instanceSettingsStoreValue.eeaMode
    @markDirty({ eeaMode: not currentValue })

    @stimulate('InstanceSettings#toggle_eea_mode')

  toggleForceSsl: (event) ->
    event.preventDefault()

    # Optimistically update store
    currentValue = @instanceSettingsStoreValue.forceSsl
    @markDirty({ forceSsl: not currentValue })

    @stimulate('InstanceSettings#toggle_force_ssl')

  toggleNoSsl: (event) ->
    event.preventDefault()

    # Optimistically update store
    currentValue = @instanceSettingsStoreValue.noSsl
    @markDirty({ noSsl: not currentValue })

    @stimulate('InstanceSettings#toggle_no_ssl')

  toggleGrpc: (event) ->
    event.preventDefault()

    # Optimistically update store
    currentValue = @instanceSettingsStoreValue.grpc
    @markDirty({ grpc: not currentValue })

    @stimulate('InstanceSettings#toggle_grpc')

  updateRailsLogLevel: (event) ->
    value = event.target.value

    # Update store
    @markDirty({ railsLogLevel: value })

    @stimulate('InstanceSettings#update_rails_log_level', value)

  updateAllowedHosts: (event) ->
    value = event.target.value

    # Update store
    @markDirty({ allowedHosts: value })

    @stimulate('InstanceSettings#update_allowed_hosts', value)

  updateCorsOrigins: (event) ->
    value = event.target.value

    # Update store
    @markDirty({ corsOrigins: value })

    @stimulate('InstanceSettings#update_cors_origins', value)

  updatePort: (event) ->
    value = event.target.value

    # Update store
    @markDirty({ port: parseInt(value, 10) or 3000 })

    @stimulate('InstanceSettings#update_port', value)

  updateAdminEmail: (event) ->
    value = event.target.value

    # Update store
    @markDirty({ adminEmail: value })

    @stimulate('InstanceSettings#update_admin_email', value)
