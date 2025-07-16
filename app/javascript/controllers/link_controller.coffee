ApplicationController = require './application_controller'
{ Turbo } = require '@hotwired/turbo-rails'
class DefaultExport extends ApplicationController
  @values = { isCurrent: Boolean }

  click: (event) ->
    event.preventDefault() # Always prevent default navigation

    if @isCurrentValue
      # Current page - just show shake animation
      @element.classList.add "sidebar-not-allowed-shake"
      setTimeout (=>
        @element.classList.remove "sidebar-not-allowed-shake"

      ), 750
    else
      # Navigate to new page using Turbo
      path = @element.getAttribute('href') or @data.get('path')
      if path
        Turbo.visit(path)


module.exports = DefaultExport
