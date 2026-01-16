# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

class CleanupAbandonedGuestsJob < ApplicationJob
  include SidekiqIteration::Iteration
  queue_as :default

  def build_enumerator(cursor:)
    cutoff_date = 30.days.ago

    # Convert to ActiveRecord relation for iteration
    Account.where(guest: true)
           .where("created_at < ?", cutoff_date)
           .order(:created_at, :id)
  end

  def each_iteration(account)
    Rails.logger.info "Cleaning up guest account #{account.id} created at #{account.created_at}"
    account.destroy
  end

  def on_start
    Rails.logger.info "Starting cleanup of abandoned guest accounts"
  end

  def on_complete
    Rails.logger.info "Successfully cleaned up abandoned guest accounts"
  end
end
