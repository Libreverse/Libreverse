# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class MapController < ApplicationController
  # Basic caching to avoid rebuilding structure on every request
  def index
    builder = MetaverseMapBuilder.new
    @map_data = builder.build
  end
end
