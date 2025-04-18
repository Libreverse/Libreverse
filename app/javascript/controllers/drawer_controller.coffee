import ApplicationController from "./application_controller"

export default class extends ApplicationController
  @targets = ["drawer", "overlay"]

  connect: ->
    super()
    # Bind `handleKeydown` to ensure `this` context is correct
    @boundHandleKeydown = @handleKeydown.bind(@)
    document.addEventListener "keydown", @boundHandleKeydown
    document.addEventListener "drawer:toggle", @handleDrawerEvent
    return

  disconnect: ->
    document.removeEventListener "keydown", @boundHandleKeydown
    document.removeEventListener "drawer:toggle", @handleDrawerEvent
    return

  handleDrawerEvent: (event) =>
    @open() if event.detail.open
    @close() if event.detail.close
    return

  handleKeydown: (event) ->
    if event.key == "Escape"
      @close()
    return

  ###*
   * Called when the drawer toggle button is clicked.
   * Triggers the DrawerReflex#toggle action on the server.
   * @param {Event} event - The click event.
  ###
  toggle: (event) ->
    event?.preventDefault()
    @stimulate "DrawerReflex#toggle"
    return

  open: ->
    # Implementation of open method
    return

  close: ->
    # Implementation of close method
    return
