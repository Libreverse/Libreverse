# frozen_string_literal: true
# shareable_constant_value: literal

class VacuumDatabaseJob < ApplicationJob
  queue_as :maintenance

  def perform
    ActiveRecord::Base.connection.execute("VACUUM;")
  end
end
