# Turbo client
import * as Turbo from "@hotwired/turbo"
import ApplicationController from "./application_controller"
import { get, post } from "@rails/request.js"

# ConsentController: handles UX and triggers ConsentReflex
export default class extends ApplicationController
  @targets = ["checkbox", "form"]

  accept: (event) ->
    event.preventDefault()
    rememberOptIn = if @hasCheckboxTarget and @checkboxTarget.checked then "1" else "0"
    post("/consent/accept", {
      body: { remember_opt_in: rememberOptIn }
      responseKind: "turbo-stream"
    }).then (response) =>
      if response.ok then response.html.then (html) => Turbo.renderStreamMessage html

  decline: (event) ->
    event.preventDefault()
    post("/consent/decline", {
      responseKind: "turbo-stream"
    }).then (response) =>
      if response.ok then response.html.then (html) => Turbo.renderStreamMessage html

  showScreen: (event) ->
    event.preventDefault()
    get("/consent/screen", {
      responseKind: "turbo-stream"
    }).then (response) =>
      if response.ok then response.html.then (html) => Turbo.renderStreamMessage html
