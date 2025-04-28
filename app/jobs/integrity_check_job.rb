# frozen_string_literal: true

class IntegrityCheckJob < ApplicationJob
  queue_as :maintenance

  def perform
    result = ActiveRecord::Base.connection.execute("PRAGMA integrity_check;")
    Rails.logger.info("Integrity check result: \\n#{result}")
  end
end
