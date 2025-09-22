# frozen_string_literal: true

# Service that constructs a synthetic 2D map layout for metaverse Experiences.
# Each distinct `metaverse_platform` is treated as a separate "continent" laid out horizontally
# in a simple CRS coordinate space consumed by Leaflet (using L.CRS.Simple on the frontend).
#
# The intent is to provide a visually separated clustering of platforms without requiring
# real-world geospatial data. We normalise each platform's internal coordinate system into a
# rectangular bounding box. Experiences missing coordinate data are placed at the centre of
# their platform's continent.
class MetaverseMapBuilder
  Provider = Struct.new(:name, :experiences, :min_x, :max_x, :min_y, :max_y, keyword_init: true) do
    def width = (max_x - min_x).positive? ? (max_x - min_x) : 1
    def height = (max_y - min_y).positive? ? (max_y - min_y) : 1
  end

  MARGIN    = 100.0   # internal padding inside a continent box for markers
  GAP       = 200.0   # horizontal gap between continents
  BASE_LINE = 0.0
  PALETTE   = %w[#1f77b4 #ff7f0e #2ca02c #d62728 #9467bd #8c564b #e377c2 #7f7f7f #bcbd22 #17becf].freeze

  def initialize(relation: Experience.where.not(metaverse_platform: nil))
    @relation = relation
  end

  def build
    providers = build_providers
    layout_providers!(providers)
    experiences_payload = build_experiences_payload(providers)

    {
      meta: {
        generated_at: Time.current.iso8601,
        provider_count: providers.size,
        total_width: providers.last&.dig(:bbox, :x_max) || 1000,
        total_height: providers.map { |p| p[:bbox][:y_max] }.max || 600
      },
      providers: providers,
      experiences: experiences_payload
    }
  end

  private

  def build_providers
    grouped = @relation.includes(:account).group_by(&:metaverse_platform)
    index = 0
    grouped.keys.sort.map do |platform|
      exps = grouped[platform]
      stats = coordinate_stats(exps)
      color = PALETTE[index % PALETTE.length]
      index += 1
      {
        name: platform,
        color: color,
        experience_count: exps.size,
        raw_bounds: stats.slice(:min_x, :max_x, :min_y, :max_y)
      }
    end
  end

  # Mutates each provider hash adding :bbox with layout coordinates
  def layout_providers!(providers)
    cursor_x = 0.0
    providers.map { |p| (p[:raw_bounds][:max_y] - p[:raw_bounds][:min_y]).abs }.max || 1
    providers.each do |p|
      raw = p[:raw_bounds]
      internal_width  = [ (raw[:max_x] - raw[:min_x]).abs, 1 ].max
      internal_height = [ (raw[:max_y] - raw[:min_y]).abs, 1 ].max
      box_width  = internal_width  + (MARGIN * 2)
      box_height = internal_height + (MARGIN * 2)
      p[:bbox] = {
        x_min: cursor_x,
        x_max: cursor_x + box_width,
        y_min: BASE_LINE,
        y_max: BASE_LINE + box_height
      }
      cursor_x = p[:bbox][:x_max] + GAP
    end
  end

  def build_experiences_payload(providers)
    # Build quick lookup for provider bounds and raw ranges
    provider_lookup = providers.to_h do |p|
      raw = p[:raw_bounds]
      [ p[:name], { raw: raw, bbox: p[:bbox], color: p[:color] } ]
    end

    @relation.find_each.map do |exp|
      provider = provider_lookup[exp.metaverse_platform]
      coords = parse_coords(exp)
      mapped = map_coordinates(coords, provider)
      {
        id: exp.id,
        title: exp.title,
        platform: exp.metaverse_platform,
        url: Rails.application.routes.url_helpers.experience_path(exp),
        original: coords.compact,
        mapped_x: mapped[:x],
        mapped_y: mapped[:y],
        color: provider[:color]
      }
    end
  end

  def coordinate_stats(experiences)
    xs = []
    ys = []
    experiences.each do |exp|
      c = parse_coords(exp)
      next unless c[:x] || c[:y]

      xs << c[:x] if c[:x]
      ys << c[:y] if c[:y]
    end
    {
      min_x: xs.min || 0.0,
      max_x: xs.max || 1.0,
      min_y: ys.min || 0.0,
      max_y: ys.max || 1.0
    }
  end

  def parse_coords(exp)
    return {} if exp.metaverse_coordinates.blank?

    json = begin
             JSON.parse(exp.metaverse_coordinates)
    rescue StandardError
             {}
    end
    {
      x: extract_number(json["x"]),
      y: extract_number(json["y"])
    }
  end

  def extract_number(v)
    case v
    when String
      begin
        Float(v)
      rescue StandardError
        nil
      end
    when Integer, Float
      v.to_f
    end
  end

  def map_coordinates(coords, provider)
    bbox = provider[:bbox]
    raw  = provider[:raw]
    # Center if missing coords
    return { x: (bbox[:x_min] + bbox[:x_max]) / 2.0, y: (bbox[:y_min] + bbox[:y_max]) / 2.0 } if coords.blank? || (coords[:x].nil? && coords[:y].nil?)

    denom_x = (raw[:max_x] - raw[:min_x]).nonzero? || 1.0
    denom_y = (raw[:max_y] - raw[:min_y]).nonzero? || 1.0

    nx = ((coords[:x] || raw[:min_x]) - raw[:min_x]) / denom_x
    ny = ((coords[:y] || raw[:min_y]) - raw[:min_y]) / denom_y

    mapped_x = bbox[:x_min] + MARGIN + nx * (bbox[:x_max] - bbox[:x_min] - (MARGIN * 2))
    mapped_y = bbox[:y_min] + MARGIN + ny * (bbox[:y_max] - bbox[:y_min] - (MARGIN * 2))
    { x: mapped_x, y: mapped_y }
  end
end
