# frozen_string_literal: true

class WalCheckpointJob < ApplicationJob
  queue_as :maintenance

  def perform
    ActiveRecord::Base.connection.execute("PRAGMA wal_checkpoint('TRUNCATE');")
  end
end
