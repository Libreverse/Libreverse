ApplicationController = require './application_controller'

###*
# * Controls dismissible elements (like banners, tutorials).
# * Hides the element immediately on click and triggers a reflex to persist the state.
###
class DefaultExport extends ApplicationController
  @values = { key: String }

  connect: ->
    super.connect()


  ###*
  # * Hides the element controlled by this controller and triggers the reflex.
  # * @param {Event} event - The click event.
  ###
  dismiss: (event) ->
    event.preventDefault()

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

    , 350


module.exports = DefaultExport
