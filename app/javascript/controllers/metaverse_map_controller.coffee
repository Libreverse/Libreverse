import ApplicationController from './application_controller'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'

# Controller responsible for rendering the synthetic metaverse map using locally bundled Leaflet (CRS.Simple)
export default class extends ApplicationController
  @values =
    dataUrl: String

  connect: ->
    super()
    @initMap()

  initMap: ->
    @element.classList.add('metaverse-map__container')
    # Resolve data URL (allow graceful fallback if attribute missing)
    unless @hasDataUrlValue
      console.warn('[MetaverseMap] data-url value missing, falling back to /map/data')
      @dataUrlValue = '/map/data'
    console.debug('[MetaverseMap] Fetching map data from', @dataUrlValue)
    @map = L.map(@element,
      crs: L.CRS.Simple
      minZoom: -2
      zoomSnap: 0.25
      wheelPxPerZoomLevel: 80
    )
    fetch(@dataUrlValue, { headers: { 'Accept': 'application/json' } })
      .then (r) => r.json()
      .then (data) => @renderData(data)
      .catch (e) => console.error('Map data load failed', e)

  renderData: (data) ->
    unless data?.meta?
      console.error('[MetaverseMap] Invalid data payload (missing meta). Aborting render.', data)
      return

    # Fallback if builder returned zero dimensions (e.g., no providers yet)
    width = data.meta.total_width or 0
    height = data.meta.total_height or 0
    if width <= 0 or height <= 0
      console.warn('[MetaverseMap] Empty dataset; using placeholder extent.')
      width = 1000
      height = 600
    
    totalBounds = [[0,0],[data.meta.total_height, data.meta.total_width]]
    @map.fitBounds([[0,0],[height,width]])

    # Draw provider rectangles
    for provider in data.providers
      rect = L.rectangle([[provider.bbox.y_min, provider.bbox.x_min],[provider.bbox.y_max, provider.bbox.x_max]],
        color: provider.color,
        weight: 1,
        fillOpacity: 0.08,
        stroke: true
      )
      rect.addTo(@map).bindPopup("<strong>#{provider.name}</strong><br/>Experiences: #{provider.experience_count}")

    markers = L.layerGroup().addTo(@map)
    for exp in data.experiences
      marker = L.circleMarker([exp.mapped_y, exp.mapped_x],
        radius: 4,
        color: exp.color,
        fillOpacity: 0.85,
        weight: 1
      )
      popup = "<strong>#{exp.title}</strong><br/>Platform: #{exp.platform}<br/><a href='#{exp.url}' data-turbo='true'>Open</a>"
      marker.bindPopup(popup)
      marker.addTo(markers)

    # Add basic legend
    legend = L.control(position: 'bottomright')
    legend.onAdd = (map) =>
      div = L.DomUtil.create('div', 'metaverse-map__legend')
      html = '<strong>Providers</strong><br/>'
      for p in data.providers
        html += "<span class='metaverse-map__swatch' style='background: #{p.color}'></span>#{p.name}<br/>"
      div.innerHTML = html
      div
    legend.addTo(@map)
