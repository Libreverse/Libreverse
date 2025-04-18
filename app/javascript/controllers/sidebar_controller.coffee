import ApplicationController from "./application_controller"

###*
 * Controls the sidebar hover interactions.
###
export default class extends ApplicationController
  connect: ->
    super.connect()
    return

  ###*
   * Called on mouseenter/mouseleave to trigger the reflex that toggles hover state.
   * Passes the element so the reflex can read data-sidebar-id.
  ###
  toggleHover: (event) ->
    @stimulate("SidebarReflex#toggle_hover", @element)
    return # Explicit return for toggleHover method

  close: ->
    @element.classList.remove "active"
    return
