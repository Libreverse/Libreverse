import ApplicationController from "./application_controller"

export default class extends ApplicationController
  connect: ->
    super.connect()
    @debounceTimers = {}

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
    @debounceUpdate('rails_log_level', event.target.value)

  updateAllowedHosts: (event) ->
    @debounceUpdate('allowed_hosts', event.target.value)

  updateCorsOrigins: (event) ->
    @debounceUpdate('cors_origins', event.target.value)

  updatePort: (event) ->
    @debounceUpdate('port', event.target.value)

  updateAdminEmail: (event) ->
    @debounceUpdate('admin_email', event.target.value)

  debounceUpdate: (setting, value) ->
    clearTimeout(@debounceTimers[setting]) if @debounceTimers[setting]
    @debounceTimers[setting] = setTimeout =>
      switch setting
        when 'rails_log_level'
          @stimulate('InstanceSettings#update_rails_log_level', value)
        when 'allowed_hosts'
          @stimulate('InstanceSettings#update_allowed_hosts', value)
        when 'cors_origins'
          @stimulate('InstanceSettings#update_cors_origins', value)
        when 'port'
          @stimulate('InstanceSettings#update_port', value)
        when 'admin_email'
          @stimulate('InstanceSettings#update_admin_email', value)
    , 1000  # 1 second debounce
