import ApplicationController from "./application_controller"

export default class extends ApplicationController
  connect: ->
    super.connect()

  toggleAutomoderation: (event) ->
    event.preventDefault()
    @stimulate('InstanceSettings#toggle_automoderation')

  toggleEeaMode: (event) ->
    event.preventDefault()
    @stimulate('InstanceSettings#toggle_eea_mode')
