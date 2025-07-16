ApplicationController = require './application_controller'
StimulusReflex = require 'stimulus_reflex'
class LanguagePickerController extends ApplicationController
  connect: ->
    StimulusReflex.register(@)

  select: (event) ->
    event.preventDefault()
    locale = event.currentTarget.dataset.locale
    @stimulate('LanguagePickerReflex#select', locale)

module.exports = LanguagePickerController
