import { Controller } from "@hotwired/stimulus"

export default class extends Controller
  @values = { isCurrent: Boolean }

  connect: ->
    # Nothing needed on connect
    return

  click: (event) ->
    if @isCurrentValue
      event.preventDefault()
      @element.classList.add "sidebar-not-allowed-shake"
      setTimeout (=>
        @element.classList.remove "sidebar-not-allowed-shake"
        return
      ), 750
    return