import { Controller } from "@hotwired/stimulus"
import StimulusReflex from "stimulus_reflex"

# This is the Stimulus ApplicationController.
# All StimulusReflex controllers should inherit from this class.
#
# Example:
#
#   import ApplicationController from './application_controller'
#
#   export default class extends ApplicationController { ... }
#
# Learn more at: https://docs.stimulusreflex.com
#

export default class extends Controller

  connect: ->
    if typeof StimulusReflex isnt 'undefined' and typeof StimulusReflex.register is 'function'
      StimulusReflex.register(@)
    else
      console.warn('StimulusReflex is not defined yet, skipping registration.')

  # Application-wide lifecycle methods have been removed as they were unused.
  # Restore them from version control if needed.
