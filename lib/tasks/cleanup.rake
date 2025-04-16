# frozen_string_literal: true

namespace :cleanup do
  desc "Clean up abandoned guest accounts older than 30 days"
  task abandoned_guests: :environment do
    # Enqueue the job through ActiveJob (which uses Solid Queue)
    CleanupAbandonedGuestsJob.perform_later
    puts "Cleanup job has been enqueued"
  end

  desc "Trigger immediate cleanup of abandoned guest accounts"
  task force_cleanup_abandoned_guests: :environment do
    # Run the job immediately
    CleanupAbandonedGuestsJob.perform_now
    puts "Immediate cleanup completed"
  end
end
