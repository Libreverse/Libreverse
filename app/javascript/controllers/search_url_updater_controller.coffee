import ApplicationController from "./application_controller"

# Connects to data-controller="search-url-updater"
export default class extends ApplicationController
  @values = {
    debounceTime: { type: Number, default: 300 }
  }

  connect: ->
    super.connect()
    @inputHandler = @handleInput.bind(@)
    @searchTimer = null

    # Set up input event listener with debounce
    @element.addEventListener "input", @inputHandler

    # Listen for successful SearchReflex completion
    @updateURLHandler = @updateURLAfterSearch.bind(@)
    document.addEventListener "stimulus-reflex:after", @updateURLHandler
    return

  disconnect: ->
    @element.removeEventListener "input", @inputHandler
    document.removeEventListener "stimulus-reflex:after", @updateURLHandler

    if @searchTimer
      clearTimeout @searchTimer
    return

  # Debounced input handler: Triggers SearchReflex
  handleInput: ->
    if @searchTimer
      clearTimeout @searchTimer

    @searchTimer = setTimeout (=>
      @stimulate "SearchReflex#perform"
      return
    ), @debounceTimeValue
    return

  # Updates the URL after SearchReflex completes successfully
  updateURLAfterSearch: (event) ->
    { reflex, error } = event.detail

    # Only proceed if SearchReflex succeeded
    if not error and reflex == "SearchReflex#perform"
      query = @element.value.trim() # Get current input value
      currentUrl = new URL(window.location.href)
      params = currentUrl.searchParams

      if query
        params.set "query", query
      else
        params.delete "query"

      # Update the URL without reloading the page and without adding a new history entry
      newUrl = currentUrl.pathname + "?" + params.toString()
      # Only replace state if the URL actually changed
      if window.location.search != params.toString()
        window.history.replaceState { path: newUrl }, "", newUrl
    return