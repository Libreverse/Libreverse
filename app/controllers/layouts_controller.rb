class LayoutsController < ApplicationController
  def sidebar
    render partial: "layouts/sidebar", layout: false
  end
end
