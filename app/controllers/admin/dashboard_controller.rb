# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

module Admin
  class DashboardController < BaseController
    def index
      # Dashboard overview - could include stats in the future
      @pending_experiences_count = Experience.where(approved: false).count
    end
  end
end
