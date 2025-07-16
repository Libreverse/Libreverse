ApplicationController = require './application_controller'
{ useStore } = require 'stimulus-store'
{ searchStore, navigationStore } = require '../stores'

###
# Search Controller with stimulus-store integration
# Manages search functionality with centralized state and URL updates
###
class DefaultExport extends ApplicationController
  @stores = [searchStore, navigationStore]

  @targets = ["input", "results", "filters", "pagination", "loading"]

  @values = {
    # Search configuration
    searchUrl: { type: String, default: "/search" },
    minQueryLength: { type: Number, default: 2 },
    debounceDelay: { type: Number, default: 300 },
    # Results configuration
    resultsPerPage: { type: Number, default: 20 },
    maxResults: { type: Number, default: 1000 },
    # UI configuration
    updateUrl: { type: Boolean, default: true },
    showFilters: { type: Boolean, default: true },
    showPagination: { type: Boolean, default: true },
    # Auto-search configuration
    autoSearch: { type: Boolean, default: true },
    searchOnLoad: { type: Boolean, default: true },
  }

  connect: ->
    console.log "[SearchController] Connected"

    # Call parent connect (sets up StimulusReflex and stores)
    super()

    # Set up input handlers for debounced search
    @inputHandler = @handleInput.bind(@)
    @element.addEventListener "debounced:input", @inputHandler

    # Set up URL update handler
    @updateURLHandler = @updateURLAfterSearch.bind(@)
    document.addEventListener "stimulus-reflex:after", @updateURLHandler

    # Initialize search state
    @initializeSearchState()

    # Set up additional event listeners
    @setupEventListeners()

    # Load initial search if configured
    if @searchOnLoadValue
      @loadInitialSearch()

  disconnect: ->
    console.log "[SearchController] Disconnecting"

    # Clean up original event listeners
    @element.removeEventListener "debounced:input", @inputHandler
    document.removeEventListener "stimulus-reflex:after", @updateURLHandler

    # Clean up additional search functionality
    @cleanupSearch()

    super()

  initializeSearchState: ->
    # Get initial query from URL or input
    initialQuery = @getInitialQuery()
    initialFilters = @getInitialFilters()

    # Initialize search store
    @searchStoreValue = {
      ...@searchStoreValue,
      query: initialQuery,
      filters: initialFilters,
      pagination: {
        ...@searchStoreValue.pagination,
        perPage: @resultsPerPageValue
      }
    }

    # Update input field
    if @hasInputTarget
      @inputTarget.value = initialQuery

  getInitialQuery: ->
    # Check URL params first
    urlParams = new URLSearchParams(globalThis.location.search)
    urlQuery = urlParams.get("q") or urlParams.get("query")

    if urlQuery
      return urlQuery

    # Check input field
    if @hasInputTarget
      return @inputTarget.value

    # Check data attribute
    @element.dataset.initialQuery or ""

  getInitialFilters: ->
    # Get filters from URL params
    urlParams = new URLSearchParams(globalThis.location.search)
    filters = {}

    # Common filter parameters
    filterParams = ["category", "type", "tag", "author", "date", "sort"]

    filterParams.forEach (param) =>
      value = urlParams.get(param)
      if value
        filters[param] = value

    filters

  setupEventListeners: ->
    # Set up input debouncing for enhanced search
    if @hasInputTarget and @autoSearchValue
      @setupDebouncedSearch()

    # Set up filter change listeners
    if @hasFiltersTarget
      @setupFilterListeners()

    # Set up pagination listeners
    if @hasPaginationTarget
      @setupPaginationListeners()

  setupDebouncedSearch: ->
    @searchTimeout = null

    @inputTarget.addEventListener "input", (event) =>
      # Clear existing timeout
      if @searchTimeout
        clearTimeout(@searchTimeout)

      # Set new timeout for debounced search
      @searchTimeout = setTimeout =>
        @performSearch(event.target.value)
      , @debounceDelayValue

  setupFilterListeners: ->
    @filtersTarget.addEventListener "change", (event) =>
      if event.target.matches("select, input[type='checkbox'], input[type='radio']")
        @updateFilters()

  setupPaginationListeners: ->
    @paginationTarget.addEventListener "click", (event) =>
      if event.target.matches("a[data-page], button[data-page]")
        event.preventDefault()
        page = Number.parseInt(event.target.dataset.page)
        @goToPage(page) if page

  loadInitialSearch: ->
    currentSearch = @searchStoreValue
    if currentSearch.query and currentSearch.query.length >= @minQueryLengthValue
      @performSearch(currentSearch.query)

  # Original SearchReflex integration
  handleInput: ->
    @stimulate "SearchReflex#perform"

  updateURLAfterSearch: (event) ->
    { reflex, error } = event.detail

    # Only proceed if SearchReflex succeeded
    if not error and reflex is "SearchReflex#perform"
      @updateURL() if @updateUrlValue

  # Enhanced search methods
  performSearch: (query) ->
    return unless query.length >= @minQueryLengthValue

    # Update store with new query
    @searchStoreValue = {
      ...@searchStoreValue,
      query: { query },
      isLoading: true,
      pagination: {
        ...@searchStoreValue.pagination,
        currentPage: 1
      }
    }

    # Show loading state
    @showLoadingState()

    # Update URL if configured
    @updateURL() if @updateUrlValue

    # Trigger search via StimulusReflex
    @stimulate "SearchReflex#perform"

  updateFilters: ->
    return unless @hasFiltersTarget

    filters = {}

    # Get all filter inputs
    filterInputs = @filtersTarget.querySelectorAll("select, input[type='checkbox']:checked, input[type='radio']:checked")

    filterInputs.forEach (input) =>
      name = input.name or input.dataset.filter
      value = input.value

      if name and value
        filters[name] = value

    # Update store
    @searchStoreValue = {
      ...@searchStoreValue,
      filters: { filters },
      pagination: {
        ...@searchStoreValue.pagination,
        currentPage: 1 # Reset to first page when filters change
      }
    }

    # Re-run search with new filters
    @performSearch(@searchStoreValue.query)

  goToPage: (page) ->
    currentSearch = @searchStoreValue

    # Update pagination in store
    @searchStoreValue = {
      ...currentSearch,
      pagination: {
        ...currentSearch.pagination,
        currentPage: page
      }
    }

    # Re-run search with new page
    @performSearch(currentSearch.query)

  showLoadingState: ->
    if @hasLoadingTarget
      @loadingTarget.style.display = "block"

    if @hasResultsTarget
      @resultsTarget.style.opacity = "0.5"

  hideLoadingState: ->
    if @hasLoadingTarget
      @loadingTarget.style.display = "none"

    if @hasResultsTarget
      @resultsTarget.style.opacity = "1"

  updateURL: ->
    return unless @updateUrlValue

    currentSearch = @searchStoreValue
    params = new URLSearchParams()

    # Add query
    if currentSearch.query
      params.set("q", currentSearch.query)

    # Add filters
    Object.entries(currentSearch.filters).forEach ([key, value]) =>
      if value
        params.set(key, value)

    # Add pagination
    if currentSearch.pagination.currentPage > 1
      params.set("page", currentSearch.pagination.currentPage)

    # Update URL without page reload
    newUrl = "#{globalThis.location.pathname}?#{params.toString()}"
    globalThis.history.replaceState({}, "", newUrl)

  cleanupSearch: ->
    if @searchTimeout
      clearTimeout(@searchTimeout)
      @searchTimeout = null

  # Store change handlers
  searchStoreChanged: ->
    # Update UI when search store changes
    @updateSearchUI()

  updateSearchUI: ->
    currentSearch = @searchStoreValue

    # Update loading state
    if currentSearch.isLoading
      @showLoadingState()
    else
      @hideLoadingState()

    # Update pagination UI if present
    @updatePaginationUI() if @hasPaginationTarget

  updatePaginationUI: ->
    return unless @hasPaginationTarget

    currentSearch = @searchStoreValue
    pagination = currentSearch.pagination

    # Update current page indicators
    currentPageElements = @paginationTarget.querySelectorAll("[data-current-page]")
    currentPageElements.forEach (element) =>
      element.textContent = pagination.currentPage

    # Update page navigation buttons
    prevButtons = @paginationTarget.querySelectorAll("[data-page='#{pagination.currentPage - 1}']")
    nextButtons = @paginationTarget.querySelectorAll("[data-page='#{pagination.currentPage + 1}']")

    prevButtons.forEach (button) =>
      button.disabled = pagination.currentPage <= 1

    nextButtons.forEach (button) =>
      button.disabled = pagination.currentPage >= pagination.totalPages

  # Public API methods
  search: (query) ->
    @performSearch(query)

  clearSearch: ->
    @searchStoreValue = {
      ...@searchStoreValue,
      query: "",
      results: [],
      pagination: {
        ...@searchStoreValue.pagination,
        currentPage: 1,
        totalPages: 0,
        totalResults: 0
      }
    }

    if @hasInputTarget
      @inputTarget.value = ""

    @updateURL() if @updateUrlValue

  getCurrentSearch: ->
    @searchStoreValue

module.exports = DefaultExport
