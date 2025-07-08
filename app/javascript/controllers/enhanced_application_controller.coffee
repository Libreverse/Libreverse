import { Controller } from "@hotwired/stimulus"
import { useStore } from "stimulus-store"
import StimulusReflex from "stimulus_reflex"
import {
  themeStore,
  glassConfigStore,
  navigationStore,
  instanceSettingsStore,
  toastStore,
  experienceStore,
  searchStore
} from "../stores"

# Enhanced Application Controller with stimulus-store integration
# This is the Stimulus ApplicationController that all other controllers inherit from.
# It sets up global state management and provides common functionality.

export default class extends Controller
  # Define all the stores that will be available to this controller and its children
  @stores = [
    themeStore,
    glassConfigStore,
    navigationStore,
    instanceSettingsStore,
    toastStore,
    experienceStore,
    searchStore
  ]

  connect: ->
    # Set up stimulus-store
    useStore(@)
    
    # Set up StimulusReflex
    if typeof StimulusReflex isnt 'undefined' and typeof StimulusReflex.register is 'function'
      StimulusReflex.register(@)
    else
      console.warn('StimulusReflex is not defined yet, skipping registration.')

    # Update navigation store with current path
    @navigationStoreValue = {
      ...@navigationStoreValue,
      currentPath: globalThis.location.pathname
    }

    # Initialize theme from localStorage or system preference
    @initializeTheme()

    # Set up global event listeners for store updates
    @setupStoreListeners()

  disconnect: ->
    # Clean up store listeners
    @cleanupStoreListeners()

  # Initialize theme from localStorage or system preference
  initializeTheme: ->
    savedTheme = localStorage.getItem("libreverse-theme")
    systemPrefersDark = globalThis.matchMedia("(prefers-color-scheme: dark)").matches
    
    currentTheme = @themeStoreValue
    
    if savedTheme
      try
        savedThemeData = JSON.parse(savedTheme)
        @themeStoreValue = { ...currentTheme, ...savedThemeData }
      catch error
        console.warn "Failed to parse saved theme:", error
    else
      @themeStoreValue = { ...currentTheme, darkMode: systemPrefersDark }

  # Set up listeners for store changes
  setupStoreListeners: ->
    # Theme changes
    @themeStoreChanged = @themeStoreChanged.bind(@)
    @element.addEventListener("themeStore:changed", @themeStoreChanged)

    # Navigation changes
    @navigationStoreChanged = @navigationStoreChanged.bind(@)
    @element.addEventListener("navigationStore:changed", @navigationStoreChanged)

    # Glass config changes
    @glassConfigStoreChanged = @glassConfigStoreChanged.bind(@)
    @element.addEventListener("glassConfigStore:changed", @glassConfigStoreChanged)

  # Clean up store listeners
  cleanupStoreListeners: ->
    @element.removeEventListener("themeStore:changed", @themeStoreChanged) if @themeStoreChanged
    @element.removeEventListener("navigationStore:changed", @navigationStoreChanged) if @navigationStoreChanged
    @element.removeEventListener("glassConfigStore:changed", @glassConfigStoreChanged) if @glassConfigStoreChanged

  # Store change handlers
  themeStoreChanged: (event) ->
    theme = event.detail.value
    
    # Save to localStorage
    localStorage.setItem("libreverse-theme", JSON.stringify(theme))
    
    # Apply theme to document
    @applyTheme(theme)

  navigationStoreChanged: (event) ->
    navigation = event.detail.value
    
    # Update page title or meta tags if needed
    @updatePageMeta(navigation)

  glassConfigStoreChanged: (event) ->
    glassConfig = event.detail.value
    
    # Trigger glass effect updates across the app
    @updateGlassEffects(glassConfig)

  # Apply theme to document
  applyTheme: (theme) ->
    document.documentElement.classList.toggle("dark", theme.darkMode)
    document.documentElement.setAttribute("data-theme", theme.currentTheme)
    document.documentElement.style.setProperty("--animations-enabled", if theme.animationsEnabled then "1" else "0")
    document.documentElement.style.setProperty("--parallax-enabled", if theme.parallaxEnabled then "1" else "0")

  # Update page meta information
  updatePageMeta: (navigation) ->
    # Update active navigation classes
    activeItem = navigation.activeItem
    if activeItem
      # Remove active class from all nav items
      document.querySelectorAll("[data-nav-item]").forEach (item) ->
        item.classList.remove("active")
      
      # Add active class to current item
      currentItem = document.querySelector("[data-nav-item='#{activeItem}']")
      currentItem?.classList.add("active")

  # Update glass effects across the app
  updateGlassEffects: (glassConfig) ->
    # Dispatch custom event for glass controllers to pick up
    glassUpdateEvent = new CustomEvent("glassConfig:updated", {
      detail: { config: glassConfig },
      bubbles: true
    })
    document.dispatchEvent(glassUpdateEvent)

  # Utility methods for child controllers
  
  # Update theme property
  updateTheme: (updates) ->
    @themeStoreValue = { ...@themeStoreValue, ...updates }

  # Update glass configuration
  updateGlassConfig: (updates) ->
    @glassConfigStoreValue = { ...@glassConfigStoreValue, ...updates }

  # Update navigation state
  updateNavigation: (updates) ->
    @navigationStoreValue = { ...@navigationStoreValue, ...updates }

  # Show toast notification
  showToast: (message, type = "info", timeout = @toastStoreValue.defaultTimeout) ->
    currentToasts = @toastStoreValue
    newToast = {
      id: currentToasts.nextId,
      message,
      type,
      timeout,
      timestamp: Date.now()
    }
    
    # Limit number of toasts
    updatedToasts = [...currentToasts.toasts, newToast]
    if updatedToasts.length > currentToasts.maxToasts
      updatedToasts = updatedToasts.slice(-currentToasts.maxToasts)
    
    @toastStoreValue = {
      ...currentToasts,
      toasts: updatedToasts,
      nextId: currentToasts.nextId + 1
    }

  # Remove toast
  removeToast: (toastId) ->
    currentToasts = @toastStoreValue
    @toastStoreValue = {
      ...currentToasts,
      toasts: currentToasts.toasts.filter((toast) -> toast.id isnt toastId)
    }

  # Check if feature is enabled
  isFeatureEnabled: (feature) ->
    switch feature
      when "glass" then @themeStoreValue.glassEnabled
      when "animations" then @themeStoreValue.animationsEnabled
      when "parallax" then @themeStoreValue.parallaxEnabled
      when "darkMode" then @themeStoreValue.darkMode
      else false

  # Get current navigation state
  getCurrentNavigation: ->
    @navigationStoreValue

  # Get current theme
  getCurrentTheme: ->
    @themeStoreValue

  # Get current glass configuration
  getCurrentGlassConfig: ->
    @glassConfigStoreValue
