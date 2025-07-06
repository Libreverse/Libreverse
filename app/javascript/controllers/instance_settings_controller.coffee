import ApplicationController from "./application_controller"

export default class extends ApplicationController
  connect: ->
    super.connect()
    return

  toggleAutomoderation: (event) ->
    event.preventDefault()
    @stimulate('InstanceSettings#toggle_automoderation')

  toggleEeaMode: (event) ->
    event.preventDefault()
    @stimulate('InstanceSettings#toggle_eea_mode')

  toggleForceSsl: (event) ->
    event.preventDefault()
    @stimulate('InstanceSettings#toggle_force_ssl')

  toggleNoSsl: (event) ->
    event.preventDefault()
    @stimulate('InstanceSettings#toggle_no_ssl')

  updateRailsLogLevel: (event) ->
    @stimulate('InstanceSettings#update_rails_log_level', event.target.value)

  updateAllowedHosts: (event) ->
    @stimulate('InstanceSettings#update_allowed_hosts', event.target.value)

  updateCorsOrigins: (event) ->
    @stimulate('InstanceSettings#update_cors_origins', event.target.value)

  updatePort: (event) ->
    @stimulate('InstanceSettings#update_port', event.target.value)

  updateAdminEmail: (event) ->
    @stimulate('InstanceSettings#update_admin_email', event.target.value)
