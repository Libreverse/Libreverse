# frozen_string_literal: true

class MapController < ApplicationController
  # Basic caching to avoid rebuilding structure on every request
  def index
  end

  def data
    builder = MetaverseMapBuilder.new
    render json: builder.build
  end
end
