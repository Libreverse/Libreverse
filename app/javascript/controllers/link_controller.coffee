import ApplicationController from "./application_controller"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends ApplicationController

  @values = { isCurrent: Boolean }

  click: (event) ->
    event.preventDefault() # Always prevent default navigation
    
    if @isCurrentValue
      # Current page - just show shake animation
      @element.classList.add "sidebar-not-allowed-shake"
      setTimeout (=>
        @element.classList.remove "sidebar-not-allowed-shake"
        return
      ), 750
    else
      # Navigate to new page using Turbo
      path = @element.getAttribute('href') || @data.get('path')
      if path
        Turbo.visit(path)
    return
