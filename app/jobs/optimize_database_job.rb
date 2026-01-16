# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class OptimizeDatabaseJob < ApplicationJob
  queue_as :maintenance

  def perform
    ActiveRecord::Base.connection.execute("PRAGMA optimize;")
  end
end
