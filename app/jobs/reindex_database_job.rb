# frozen_string_literal: true

class ReindexDatabaseJob < ApplicationJob
  queue_as :maintenance

  def perform
    ActiveRecord::Base.connection.execute("REINDEX;")
  end
end
