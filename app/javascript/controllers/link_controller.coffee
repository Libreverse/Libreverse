import ApplicationController from "./application_controller"

export default class extends ApplicationController
  @values = { isCurrent: Boolean }

  click: (event) ->
    if @isCurrentValue
      event.preventDefault()
      @element.classList.add "sidebar-not-allowed-shake"
      setTimeout (=>
        @element.classList.remove "sidebar-not-allowed-shake"
        return
      ), 750
    return

  # Exit if target element is not found
