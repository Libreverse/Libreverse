import * as Turbo from "@hotwired/turbo"
import ApplicationController from "./application_controller"
import { get, post } from "@rails/request.js"
import Cookies from "js-cookie"

# ConsentController: handles UX and triggers ConsentReflex
export default class extends ApplicationController
  @targets = ["checkbox", "form"]

  connect: ->
    super.connect()
    # Check if consent already given via cookie (for UI purposes)
    if Cookies.get("privacy_consent") == "1"
      @hideConsentUI()
    return

  accept: (event) ->
    event.preventDefault()
    rememberOptIn = if @hasCheckboxTarget and @checkboxTarget.checked then "true" else "false"
    
    # Trigger Reflex
    # Pass data via element dataset instead of arguments to avoid argument mismatch
    @element.dataset.rememberOptIn = rememberOptIn
    @stimulate("ConsentReflex#accept")

  decline: (event) ->
    # Handled by data-reflex in HTML
    event.preventDefault()

  showScreen: (event) ->
    event.preventDefault()
    get("/consent/screen", {
      responseKind: "turbo-stream"
    }).then (response) =>
      if response.ok then response.html.then (html) => Turbo.renderStreamMessage html

  hideConsentUI: ->
    # Hide consent UI elements if already accepted
    consentElements = document.querySelectorAll('.consent-overlay, .consent-banner')
    consentElements.forEach (el) -> el.style.display = 'none'

  # Collect invisible captcha data from the current page
  getCaptchaData: ->
    data = {}

    # Find honeypot field (has random hex name)
    honeypotField = document.querySelector('input[type="text"][name^=""][style*="display:none"], input[type="text"][name^=""][style*="visibility:hidden"]')
    if honeypotField?.name?.match(/^[a-f0-9]{8,}$/)
      data[honeypotField.name] = honeypotField.value or ""

    # Find timestamp field
    timestampField = document.querySelector('input[name="invisible_captcha_timestamp"]')
    if timestampField
      data.invisible_captcha_timestamp = timestampField.value

    data
