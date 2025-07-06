import { Controller } from "@hotwired/stimulus"
import { useStore } from "stimulus-store"
import { searchStore, navigationStore } from "../stores"

###
Enhanced Search Controller with stimulus-store integration
Manages search functionality with centralized state and URL updates
###
export default class extends Controller
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
    console.log "[EnhancedSearchController] Connected"
    
    # Set up stimulus-store
    useStore(@)
    
    # Initialize search state
    @initializeSearchState()
    
    # Set up event listeners
    @setupEventListeners()
    
    # Load initial search if configured
    if @searchOnLoadValue
      @loadInitialSearch()

  disconnect: ->
    console.log "[EnhancedSearchController] Disconnecting"
    
    # Clean up timers and listeners
    @cleanupSearch()

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
    
    # Check for custom filters in data attributes
    customFilters = @element.dataset.initialFilters
    if customFilters
      try
        Object.assign(filters, JSON.parse(customFilters))
      catch error
        console.warn "Failed to parse initial filters:", error
    
    filters

  setupEventListeners: ->
    # Search input handling
    if @hasInputTarget
      @inputTarget.addEventListener("input", @handleSearchInput.bind(@))
      @inputTarget.addEventListener("keydown", @handleSearchKeydown.bind(@))
    
    # Filter change handling
    if @hasFiltersTarget
      @filtersTarget.addEventListener("change", @handleFilterChange.bind(@))
    
    # Pagination handling
    if @hasPaginationTarget
      @paginationTarget.addEventListener("click", @handlePaginationClick.bind(@))
    
    # Form submission handling
    @element.addEventListener("submit", @handleFormSubmit.bind(@))
    
    # Store change listeners
    @searchStoreChanged = @handleSearchStoreChange.bind(@)
    @element.addEventListener("searchStore:changed", @searchStoreChanged)
    
    # Browser back/forward handling
    globalThis.addEventListener("popstate", @handlePopState.bind(@))

  cleanupSearch: ->
    # Clear debounce timer
    if @debounceTimer
      clearTimeout(@debounceTimer)
      @debounceTimer = undefined
    
    # Remove event listeners
    globalThis.removeEventListener("popstate", @handlePopState) if @handlePopState
    @element.removeEventListener("searchStore:changed", @searchStoreChanged) if @searchStoreChanged

  loadInitialSearch: ->
    searchState = @searchStoreValue
    
    # Perform search if there's a query or filters
    if searchState.query or Object.keys(searchState.filters).length > 0
      @performSearch()

  # Event handlers
  handleSearchInput: (event) ->
    query = event.target.value.trim()
    
    # Clear previous timer
    if @debounceTimer
      clearTimeout(@debounceTimer)
    
    # Update store immediately for responsive UI
    @searchStoreValue = {
      ...@searchStoreValue,
      query: query
    }
    
    # Skip search if query is too short
    if query.length < @minQueryLengthValue and query.length > 0
      @showSearchHint()
      return
    
    # Debounce the actual search
    if @autoSearchValue
      @debounceTimer = setTimeout =>
        @performSearch()
      , @debounceDelayValue

  handleSearchKeydown: (event) ->
    if event.key is "Enter"
      event.preventDefault()
      @performSearch()

  handleFilterChange: (event) ->
    # Get all filter values
    filters = @getFilterValues()
    
    # Update store
    @searchStoreValue = {
      ...@searchStoreValue,
      filters: filters,
      pagination: {
        ...@searchStoreValue.pagination,
        page: 1 # Reset to first page when filters change
      }
    }
    
    # Perform new search
    @performSearch()

  handlePaginationClick: (event) ->
    event.preventDefault()
    
    target = event.target.closest("[data-page]")
    return unless target
    
    page = parseInt(target.dataset.page)
    return if isNaN(page)
    
    # Update pagination in store
    @searchStoreValue = {
      ...@searchStoreValue,
      pagination: {
        ...@searchStoreValue.pagination,
        page: page
      }
    }
    
    # Perform search with new page
    @performSearch()

  handleFormSubmit: (event) ->
    event.preventDefault()
    @performSearch()

  handleSearchStoreChange: (event) ->
    searchState = event.detail.value
    
    # Update URL if configured
    if @updateUrlValue
      @updateUrl(searchState)
    
    # Update UI elements
    @updateSearchUI(searchState)

  handlePopState: (event) ->
    # Handle browser back/forward
    @initializeSearchState()
    @performSearch()

  # Search methods
  performSearch: ->
    searchState = @searchStoreValue
    
    # Don't search if query is too short
    if searchState.query.length < @minQueryLengthValue and searchState.query.length > 0
      return
    
    # Show loading state
    @showLoadingState()
    
    # Build search parameters
    searchParams = @buildSearchParams(searchState)
    
    # Perform search request
    @executeSearch(searchParams)

  buildSearchParams: (searchState) ->
    params = new URLSearchParams()
    
    # Add query
    if searchState.query
      params.append("q", searchState.query)
    
    # Add filters
    Object.entries(searchState.filters).forEach ([key, value]) =>
      if value
        params.append(key, value)
    
    # Add pagination
    if searchState.pagination.page > 1
      params.append("page", searchState.pagination.page)
    
    if searchState.pagination.perPage isnt @resultsPerPageValue
      params.append("per_page", searchState.pagination.perPage)
    
    params

  executeSearch: (params) ->
    # Mark as loading
    @searchStoreValue = {
      ...@searchStoreValue,
      isLoading: true
    }
    
    # Build search URL
    searchUrl = new URL(@searchUrlValue, globalThis.location.origin)
    searchUrl.search = params.toString()
    
    # Execute search via fetch
    fetch(searchUrl, {
      method: "GET",
      headers: {
        "Accept": "application/json",
        "X-Requested-With": "XMLHttpRequest"
      }
    })
    .then (response) =>
      if response.ok
        response.json()
      else
        throw new Error("Search request failed")
    
    .then (data) =>
      @handleSearchSuccess(data)
    
    .catch (error) =>
      @handleSearchError(error)

  handleSearchSuccess: (data) ->
    # Update search store with results
    @searchStoreValue = {
      ...@searchStoreValue,
      results: data.results or [],
      pagination: {
        ...@searchStoreValue.pagination,
        page: data.pagination?.page or 1,
        totalPages: data.pagination?.totalPages or 1,
        perPage: data.pagination?.perPage or @resultsPerPageValue
      },
      isLoading: false
    }
    
    # Update results display
    @updateResultsDisplay(data)
    
    # Dispatch success event
    @dispatchSearchEvent("search:success", data)

  handleSearchError: (error) ->
    console.error "[EnhancedSearchController] Search error:", error
    
    # Update store
    @searchStoreValue = {
      ...@searchStoreValue,
      isLoading: false
    }
    
    # Show error message
    @showErrorMessage("Search failed. Please try again.")
    
    # Dispatch error event
    @dispatchSearchEvent("search:error", error)

  # UI update methods
  updateResultsDisplay: (data) ->
    return unless @hasResultsTarget
    
    if data.results and data.results.length > 0
      @renderResults(data.results)
    else
      @showNoResults()
    
    # Update pagination
    if @hasPaginationTarget and @showPaginationValue
      @updatePagination(data.pagination)

  renderResults: (results) ->
    # Clear existing results
    @resultsTarget.innerHTML = ""
    
    # Render each result
    results.forEach (result) =>
      resultElement = @createResultElement(result)
      @resultsTarget.appendChild(resultElement)

  createResultElement: (result) ->
    element = document.createElement("div")
    element.className = "search-result"
    element.innerHTML = """
      <div class="search-result-content">
        <h3 class="search-result-title">
          <a href="#{result.url or '#'}">#{result.title or 'Untitled'}</a>
        </h3>
        <p class="search-result-description">#{result.description or ''}</p>
        <div class="search-result-meta">
          #{if result.author then '<span class="author">' + result.author + '</span>' else ''}
          #{if result.date then '<span class="date">' + result.date + '</span>' else ''}
          #{if result.category then '<span class="category">' + result.category + '</span>' else ''}
        </div>
      </div>
    """
    
    element

  showNoResults: ->
    @resultsTarget.innerHTML = """
      <div class="search-no-results">
        <p>No results found for your search.</p>
        <p>Try adjusting your search terms or filters.</p>
      </div>
    """

  updatePagination: (pagination) ->
    return unless @hasPaginationTarget
    
    # Clear existing pagination
    @paginationTarget.innerHTML = ""
    
    # Don't show pagination if only one page
    return if pagination.totalPages <= 1
    
    # Create pagination elements
    paginationHTML = @buildPaginationHTML(pagination)
    @paginationTarget.innerHTML = paginationHTML

  buildPaginationHTML: (pagination) ->
    html = '<div class="pagination">'
    
    # Previous button
    if pagination.page > 1
      html += """<a href="#" class="pagination-prev" data-page="#{pagination.page - 1}">Previous</a>"""
    
    # Page numbers
    startPage = Math.max(1, pagination.page - 2)
    endPage = Math.min(pagination.totalPages, pagination.page + 2)
    
    for page in [startPage..endPage]
      if page is pagination.page
        html += """<span class="pagination-current">#{page}</span>"""
      else
        html += """<a href="#" class="pagination-page" data-page="#{page}">#{page}</a>"""
    
    # Next button
    if pagination.page < pagination.totalPages
      html += """<a href="#" class="pagination-next" data-page="#{pagination.page + 1}">Next</a>"""
    
    html += '</div>'
    html

  showLoadingState: ->
    if @hasLoadingTarget
      @loadingTarget.style.display = "block"
    
    if @hasResultsTarget
      @resultsTarget.classList.add("loading")

  hideLoadingState: ->
    if @hasLoadingTarget
      @loadingTarget.style.display = "none"
    
    if @hasResultsTarget
      @resultsTarget.classList.remove("loading")

  showErrorMessage: (message) ->
    if @hasResultsTarget
      @resultsTarget.innerHTML = """
        <div class="search-error">
          <p>#{message}</p>
        </div>
      """

  showSearchHint: ->
    if @hasResultsTarget
      @resultsTarget.innerHTML = """
        <div class="search-hint">
          <p>Enter at least #{@minQueryLengthValue} characters to search.</p>
        </div>
      """

  updateSearchUI: (searchState) ->
    # Update loading state
    if searchState.isLoading
      @showLoadingState()
    else
      @hideLoadingState()
    
    # Update input field
    if @hasInputTarget and @inputTarget.value isnt searchState.query
      @inputTarget.value = searchState.query
    
    # Update filter displays
    @updateFilterUI(searchState.filters)

  updateFilterUI: (filters) ->
    return unless @hasFiltersTarget
    
    # Update filter form elements
    filterElements = @filtersTarget.querySelectorAll("[name]")
    filterElements.forEach (element) =>
      filterName = element.name
      filterValue = filters[filterName]
      
      if element.type is "checkbox"
        element.checked = !!filterValue
      else if element.type is "radio"
        element.checked = element.value is filterValue
      else
        element.value = filterValue or ""

  # Utility methods
  getFilterValues: ->
    return {} unless @hasFiltersTarget
    
    filters = {}
    formData = new FormData(@filtersTarget)
    
    for [key, value] from formData.entries()
      filters[key] = value
    
    filters

  updateUrl: (searchState) ->
    params = new URLSearchParams()
    
    # Add query
    if searchState.query
      params.append("q", searchState.query)
    
    # Add filters
    Object.entries(searchState.filters).forEach ([key, value]) =>
      if value
        params.append(key, value)
    
    # Add pagination if not first page
    if searchState.pagination.page > 1
      params.append("page", searchState.pagination.page)
    
    # Update URL without triggering navigation
    newUrl = "#{globalThis.location.pathname}?#{params.toString()}"
    globalThis.history.replaceState({}, "", newUrl)

  dispatchSearchEvent: (eventName, data) ->
    event = new CustomEvent(eventName, {
      detail: data,
      bubbles: true
    })
    @element.dispatchEvent(event)

  # Public API
  search: (query, filters = {}) ->
    @searchStoreValue = {
      ...@searchStoreValue,
      query: query,
      filters: filters,
      pagination: {
        ...@searchStoreValue.pagination,
        page: 1
      }
    }
    
    @performSearch()

  clearSearch: ->
    @searchStoreValue = {
      ...@searchStoreValue,
      query: "",
      filters: {},
      results: [],
      pagination: {
        ...@searchStoreValue.pagination,
        page: 1
      }
    }
    
    if @hasInputTarget
      @inputTarget.value = ""
    
    if @hasResultsTarget
      @resultsTarget.innerHTML = ""

  getCurrentSearch: ->
    @searchStoreValue

  addFilter: (key, value) ->
    @searchStoreValue = {
      ...@searchStoreValue,
      filters: {
        ...@searchStoreValue.filters,
        [key]: value
      },
      pagination: {
        ...@searchStoreValue.pagination,
        page: 1
      }
    }
    
    @performSearch()

  removeFilter: (key) ->
    currentFilters = { ...@searchStoreValue.filters }
    delete currentFilters[key]
    
    @searchStoreValue = {
      ...@searchStoreValue,
      filters: currentFilters,
      pagination: {
        ...@searchStoreValue.pagination,
        page: 1
      }
    }
    
    @performSearch()

  goToPage: (page) ->
    @searchStoreValue = {
      ...@searchStoreValue,
      pagination: {
        ...@searchStoreValue.pagination,
        page: page
      }
    }
    
    @performSearch()
