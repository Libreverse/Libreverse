import ApplicationController from "./application_controller"

# SyncModeController: toggles between strict and relaxed sync modes
export default class extends ApplicationController
  @targets = ["checkbox", "status"]

  connect: ->
    @updateStatus()

  toggle: ->
    mode = if @checkboxTarget.checked then "relaxed" else "strict"
    window.dispatchEvent(new CustomEvent("sync-mode-changed", { detail: { mode } }))
    @updateStatus()

  updateStatus: ->
    if @checkboxTarget.checked
      @statusTarget.textContent = "Relaxed (synces on visibility change)"
    else
      @statusTarget.textContent = "Strict (default)"
