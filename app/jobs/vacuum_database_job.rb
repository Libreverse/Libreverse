class VacuumDatabaseJob < ApplicationJob
  queue_as :maintenance

  def perform
    ActiveRecord::Base.connection.execute("VACUUM;")
  end
end
