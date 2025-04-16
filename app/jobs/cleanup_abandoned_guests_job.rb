# frozen_string_literal: true

class CleanupAbandonedGuestsJob < ApplicationJob
  queue_as :default

  def perform
    # Find guest accounts older than 30 days
    cutoff_date = 30.days.ago

    # Log the cleanup operation
    Rails.logger.info "Starting cleanup of abandoned guest accounts older than #{cutoff_date}"

    # Find abandoned guest accounts
    abandoned_guests = Account.where(guest: true)
                              .where("created_at < ?", cutoff_date)

    count = abandoned_guests.count
    Rails.logger.info "Found #{count} abandoned guest accounts to clean up"

    # Delete the accounts and their associated preferences
    return unless count.positive?

      # To ensure proper cleanup, we'll use transaction and destroy each record
      Account.transaction do
        abandoned_guests.find_each do |account|
          # Log the account being deleted
          Rails.logger.info "Cleaning up guest account #{account.id} created at #{account.created_at}"

          # Delete the account and its associated preferences
          account.destroy
        end
      end

      Rails.logger.info "Successfully cleaned up #{count} abandoned guest accounts"
  end
end
