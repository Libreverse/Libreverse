class OptimizeDatabaseJob < ApplicationJob
  queue_as :maintenance

  def perform
    ActiveRecord::Base.connection.execute("PRAGMA optimize;")
  end
end
