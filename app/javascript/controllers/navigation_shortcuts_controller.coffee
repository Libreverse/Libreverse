import ApplicationController from "./application_controller"
import { useHotkeys } from "stimulus-use/hotkeys"
import { visit } from "@hotwired/turbo"

export default class extends ApplicationController
  @targets = []

  connect: ->
    super()
    useHotkeys @, {
      hotkeys: {
        h: {
          handler: @goHome.bind(@)
        }
        s: {
          handler: @goSearch.bind(@)
        }
        d: {
          handler: @openDrawer.bind(@)
        }
      }
      filter: (event) =>
        event.target.tagName isnt "INPUT" and
        event.target.tagName isnt "TEXTAREA" and
        not event.ctrlKey and
        not event.altKey
    }
    return

  goHome: (event) ->
    event.preventDefault()
    if globalThis.location.pathname isnt "/"
      visit "/"
    return

  goSearch: (event) ->
    event.preventDefault()
    if globalThis.location.pathname isnt "/search"
      visit "/search"
    return

  openDrawer: (event) ->
    event.preventDefault()
    # Find the drawer controller and toggle it directly
    drawerElement = document.querySelector("#main-drawer")
    if drawerElement
      # Get the Stimulus controller instance using the newer API
      drawerController = @application.getControllerForElementAndIdentifier(drawerElement, "glass-drawer")
      if drawerController
        drawerController.toggle(event)
      else
        # Fallback: dispatch a custom event that the drawer can listen to
        drawerElement.dispatchEvent(new CustomEvent('drawer:toggle', {
          detail: { drawerId: 'main', open: !drawerElement.querySelector('.drawer').classList.contains('drawer-expanded') },
          bubbles: true
        }))
    else
      console.warn("Could not find main drawer element")
    return
