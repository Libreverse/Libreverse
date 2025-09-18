import ApplicationController from "./application_controller"
import Cookies from "js-cookie"

###*
 * Controls dismissible elements (like banners, tutorials).
 * Hides the element immediately on click and triggers a reflex to persist the state.
###
export default class extends ApplicationController
  @values = { key: String }

  connect: ->
    super.connect()
    # Check if already dismissed via cookie
    if @keyValue and Cookies.get("dismissed_#{@keyValue}")
      @element.style.display = 'none'
    return

  ###*
   * Hides the element controlled by this controller and triggers the reflex.
   * @param {Event} event - The click event.
  ###
  dismiss: (event) ->
    event.preventDefault()

    # Set cookie to remember dismissal
    if @keyValue
      Cookies.set("dismissed_#{@keyValue}", "true", { expires: 30 })

    # Call the server-side Reflex method to handle dismissal logic
    @stimulate "DismissibleReflex#dismiss", @element

    # Animate and remove the element from the DOM
    element = @element
    element.style.height = "#{element.offsetHeight}px"
    element.style.transition = "height 0.35s ease-in, padding 0.35s ease-in, opacity 0.2s ease-in"
    element.style.paddingTop = "0"
    element.style.paddingBottom = "0"
    element.style.height = "0"
    element.style.opacity = "0"

    setTimeout =>
      element.parentNode.removeChild element
      return
    , 350
    return
