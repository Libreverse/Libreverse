# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :firefox, screen_size: [ 1400, 1400 ] do |driver_option|
    driver_option.add_argument("--headless")
    driver_option.add_argument("--disable-gpu")
    driver_option.add_argument("--no-remote")
    driver_option.add_argument("--disable-extensions")
  end
end
