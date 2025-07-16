# Experience_upload_controller.coffee
ApplicationController = require './application_controller'
class DefaultExport extends ApplicationController
  @targets = ['error']

  connect: ->
    # The element is now the file input itself
    @dropzone = @element
    @dropzone.classList.remove('dropzone--active')

  disconnect: ->
    # No need to remove event listeners as they're handled by Stimulus


  handleChange: (event) ->
    # Clear any previous errors when a file is selected
    @clearError()
    # No client-side file validation; server will validate type and size

  clearError: ->
    if @hasErrorTarget
      @errorTarget.style.display = 'none'
      @errorTarget.textContent = ''

  dragOver: (event) ->
    event.preventDefault()
    event.stopPropagation()
    @dropzone.classList.add('dropzone--active')

  dragLeave: (event) ->
    event.preventDefault()
    event.stopPropagation()
    @dropzone.classList.remove('dropzone--active')

  drop: (event) ->
    event.preventDefault()
    event.stopPropagation()

    @dropzone.classList.remove('dropzone--active')
    @clearError()

    files = event.dataTransfer?.files
    if files and files.length > 0
      # Only accept the first file
      file = files[0]
      # No client-side file validation; server will validate type and size

      # Since the element is already the file input, we can set files directly
      dataTransfer = new DataTransfer()
      dataTransfer.items.add(file)
      @element.files = dataTransfer.files

      # Trigger change event for direct upload
      evt = new Event('change', { bubbles: true })
      @element.dispatchEvent(evt)

  showError: (msg) ->
    if @hasErrorTarget
      @errorTarget.textContent = msg
      @errorTarget.style.display = 'block'

module.exports = DefaultExport
