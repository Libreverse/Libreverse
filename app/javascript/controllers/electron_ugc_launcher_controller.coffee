import { Controller } from '@hotwired/stimulus'

# Posts a request to the Electron wrapper to open a sandboxed BrowserView.
# Safe to include on the web too: without Electron, nothing listens.
export default class extends Controller
  @values:
    url: String
    autoOpen: { type: Boolean, default: true }

  connect: ->
    return unless @hasUrlValue
    if @autoOpenValue
      @open()

  open: (event) ->
    event?.preventDefault?()

    payload =
      type: 'libreverse.ugc.open'
      url: @urlValue

    try
      window.parent?.postMessage(payload, '*')
    catch
      # ignore
