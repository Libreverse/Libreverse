import ApplicationController from "./application_controller"

# ConsentController: handles UX tweaks on the consent screen
export default class extends ApplicationController
  @targets = ["checkbox", "form"]

  connect: ->
    # Nothing fancy yet; could add analytics‑free logging or animations
    null
