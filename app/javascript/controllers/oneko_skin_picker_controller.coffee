import ApplicationController from './application_controller'
import StimulusReflex from 'stimulus_reflex'

export default class OnekoSkinPickerController extends ApplicationController
  select: (event) ->
    event.preventDefault()
    skin = event.currentTarget.dataset.skin
    @stimulate('OnekoSkinPickerReflex#select', skin)