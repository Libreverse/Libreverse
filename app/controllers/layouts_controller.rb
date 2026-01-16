# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class LayoutsController < ApplicationController
  def sidebar
    render partial: "layouts/sidebar", layout: false
  end
end
