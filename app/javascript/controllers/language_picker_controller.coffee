import ApplicationController from './application_controller'
import StimulusReflex from 'stimulus_reflex'

export default class LanguagePickerController extends ApplicationController
  connect: ->
    StimulusReflex.register(@)

  select: (event) ->
    event.preventDefault()
    locale = event.currentTarget.dataset.locale
    @stimulate('LanguagePickerReflex#select', locale)
