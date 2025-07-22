import ApplicationController from "./application_controller"

# Connects to data-controller="admin-litestream"
export default class extends ApplicationController
  @targets = ["modal", "modalTitle", "modalContent"]

  connect: ->
    super.connect()
    console.log "Litestream admin controller connected"

  showGenerations: (event) =>
    database = event.target.dataset.database
    @showModal "Generations for #{database}", =>
      @loadGenerations(database)

  showSnapshots: (event) =>
    database = event.target.dataset.database
    @showModal "Snapshots for #{database}", =>
      @loadSnapshots(database)

  verifyDatabase: (event) ->
    database = event.target.dataset.database
    event.target.disabled = true
    event.target.textContent = "Verifying..."

    @verifyDatabaseBackup database, (result) =>
      event.target.disabled = false
      event.target.textContent = "Verify Backup"

      if result.success
        @showNotification "Database verification successful", "success"
      else
        @showNotification "Verification failed: #{result.error}", "error"

  refreshStatus: ->
    location.reload()

  closeModal: ->
    modal = document.getElementById('details-modal')
    modal?.classList.add('hidden')

  # Private methods
  showModal: (title, contentLoader) =>
    modal = document.getElementById('details-modal')
    titleEl = document.getElementById('modal-title')
    contentEl = document.getElementById('modal-content')

    titleEl.textContent = title
    contentEl.innerHTML = "Loading..."
    modal.classList.remove('hidden')

    contentLoader?.call(@)

  loadGenerations: (database) =>
    fetch "/admin/litestream/generations?database=#{encodeURIComponent(database)}"
      .then (response) => response.json()
      .then (data) =>
        @displayGenerations(data)
      .catch (error) =>
        @displayError("Failed to load generations: #{error.message}")

  loadSnapshots: (database) =>
    fetch "/admin/litestream/snapshots?database=#{encodeURIComponent(database)}"
      .then (response) => response.json()
      .then (data) =>
        @displaySnapshots(data)
      .catch (error) =>
        @displayError("Failed to load snapshots: #{error.message}")

  verifyDatabaseBackup: (database, callback) =>
    fetch "/admin/litestream/verify",
      method: 'POST'
      headers:
        'Content-Type': 'application/json'
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
      body: JSON.stringify(database: database)
    .then (response) => response.json()
    .then (data) =>
      callback(data)
    .catch (error) =>
      callback(success: false, error: error.message)

  displayGenerations: (generations) =>
    contentEl = document.getElementById('modal-content')

    if generations.length is 0
      contentEl.innerHTML = "<p class='text-gray-500'>No generations found.</p>"
      return

    html = """
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Generation</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Lag</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Start</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">End</th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
    """

    for generation in generations
      html += """
        <tr>
          <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">#{generation.name}</td>
          <td class="px-6 py-4 whitespace-nowrap text-sm font-mono text-gray-900">#{generation.generation}</td>
          <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">#{generation.lag}</td>
          <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">#{generation.start}</td>
          <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">#{generation.end}</td>
        </tr>
      """

    html += """
          </tbody>
        </table>
      </div>
    """

    contentEl.innerHTML = html

  displaySnapshots: (snapshots) =>
    contentEl = document.getElementById('modal-content')

    if snapshots.length is 0
      contentEl.innerHTML = "<p class='text-gray-500'>No snapshots found.</p>"
      return

    html = """
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Replica</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Generation</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Index</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Size</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created</th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
    """

    for snapshot in snapshots
      html += """
        <tr>
          <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">#{snapshot.replica}</td>
          <td class="px-6 py-4 whitespace-nowrap text-sm font-mono text-gray-900">#{snapshot.generation}</td>
          <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">#{snapshot.index}</td>
          <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">#{@formatBytes(parseInt(snapshot.size))}</td>
          <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">#{@formatDate(snapshot.created)}</td>
        </tr>
      """

    html += """
          </tbody>
        </table>
      </div>
    """

    contentEl.innerHTML = html

  displayError: (message) =>
    contentEl = document.getElementById('modal-content')
    contentEl.innerHTML = "<p class='text-red-500'>#{message}</p>"

  formatBytes: (bytes) =>
    if bytes is 0 then return '0 Bytes'

    k = 1024
    sizes = ['Bytes', 'KB', 'MB', 'GB']
    i = Math.floor(Math.log(bytes) / Math.log(k))

    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]

  formatDate: (dateString) =>
    date = new Date(dateString)
    return date.toLocaleString()

  showNotification: (message, type = "info") =>
    # Create notification element
    notification = document.createElement('div')
    notification.className = """
      fixed top-4 right-4 z-50 px-4 py-2 rounded-md shadow-lg text-white max-w-sm
      #{if type is 'success' then 'bg-green-500' else if type is 'error' then 'bg-red-500' else 'bg-blue-500'}
    """
    notification.textContent = message

    document.body.appendChild(notification)

    # Auto-remove after 5 seconds
    setTimeout =>
      notification.remove()
    , 5000
