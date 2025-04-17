import ApplicationController from "./application_controller"

###*
 * Controls dismissible elements (like banners, tutorials).
 * Hides the element immediately on click and triggers a reflex to persist the state.
###
export default class extends ApplicationController
  # Define the data value expected from the HTML (data-dismissible-key-value)
  @values = { key: String }

  connect: ->
    super.connect()
    # console.log("Dismissible controller connected for key: #{@keyValue}")
    return

  ###*
   * Hides the element controlled by this controller and triggers the reflex.
   * @param {Event} event - The click event.
  ###
  dismiss: (event) ->
    event.preventDefault()
    event.stopPropagation() # Prevent event bubbling if needed

    # 1. Hide the element immediately for good UX
    @element.classList.add "dismissed" # Add a class for CSS hiding/transition
    # Optionally: Use display: none; if preferred over class-based hiding
    # @element.style.display = 'none'

    # 2. Trigger the reflex to persist the state
    # Pass the element itself so the reflex can access its dataset (key)
    @stimulate "DismissibleReflex#dismiss", @element

    # Optional: Add client-side callbacks for feedback
    # @stimulate('DismissibleReflex#dismiss', @element).then(() =>
    #   console.log("Dismiss persisted for key: #{@keyValue}")
    # ).catch(error =>
    #   console.error("Error persisting dismiss for key: #{@keyValue}", error)
    #   # Optionally: Re-show the element if persistence failed?
    #   @element.classList.remove('dismissed')
    # )
    return