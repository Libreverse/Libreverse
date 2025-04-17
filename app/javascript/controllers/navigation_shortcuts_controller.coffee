import { Controller } from "@hotwired/stimulus"
import { useHotkeys } from "stimulus-use/hotkeys"
import { visit } from "@hotwired/turbo"

export default class extends Controller
  @targets = []

  connect: ->
    useHotkeys @, {
      hotkeys: {
        h: {
          handler: @goHome.bind(@)
        }
        s: {
          handler: @goSearch.bind(@)
        }
      }
      filter: (event) ->
        event.target.tagName != "INPUT" and
        event.target.tagName != "TEXTAREA" and
        not event.ctrlKey and
        not event.altKey
    }
    return

  goHome: (event) ->
    event.preventDefault()
    if globalThis.location.pathname != "/"
      visit "/"
    return

  goSearch: (event) ->
    event.preventDefault()
    if globalThis.location.pathname != "/search"
      visit "/search"
    return