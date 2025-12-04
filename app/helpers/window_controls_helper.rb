# frozen_string_literal: true
# shareable_constant_value: literal

module WindowControlsHelper
  # SVG circle base template (URL-encoded)
  CIRCLE_SVG_TEMPLATE = "data:image/svg+xml;charset=utf-8,%3csvg enable-background='new 0 0 85.4 85.4' viewBox='0 0 85.4 85.4' xmlns='http://www.w3.org/2000/svg'%3e%3cg clip-rule='evenodd' fill-rule='evenodd'%3e%3cpath d='m42.7 85.4c23.6 0 42.7-19.1 42.7-42.7s-19.1-42.7-42.7-42.7-42.7 19.1-42.7 42.7 19.1 42.7 42.7 42.7z' fill='%23OUTER'/%3e%3cpath d='m42.7 81.8c21.6 0 39.1-17.5 39.1-39.1s-17.5-39.1-39.1-39.1-39.1 17.5-39.1 39.1 17.5 39.1 39.1 39.1z' fill='%23INNER'/%3e%3c/g%3e%3c/svg%3e"

  # Color schemes for traffic light buttons
  TRAFFIC_LIGHT_COLORS = {
    close: { macos: %w[e24b41 ed6a5f], grayscale: %w[888888 aaaaaa] },
    minimize: { macos: %w[e1a73e f6be50], grayscale: %w[888888 aaaaaa] },
    maximize: { macos: %w[2dac2f 61c555], grayscale: %w[888888 aaaaaa] }
  }.freeze

  def traffic_light_src(button, is_macos)
    colors = TRAFFIC_LIGHT_COLORS[button]
    scheme = is_macos ? :macos : :grayscale
    outer, inner = colors[scheme]

    CIRCLE_SVG_TEMPLATE.gsub("OUTER", outer).gsub("INNER", inner)
  end

  def is_macos_platform?
    params[:platform] == "darwin" && ENV["FORCE_GRAYSCALE_TRAFFIC_LIGHTS"] != "true"
  end
end
