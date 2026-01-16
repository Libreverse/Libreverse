# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

# Job to handle federating experience deletion activities via ActivityPub
class FederateExperienceDeletionJob < ApplicationJob
  queue_as :federation

  def perform(experience_uri)
    # For now, just log the deletion - full delivery can be implemented later
    Rails.logger.info "Would federate deletion for experience URI: #{experience_uri}"

    # TODO: Implement actual deletion activity delivery
    # This would involve:
    # 1. Finding the original actor
    # 2. Creating a Delete activity
    # 3. Delivering to follower inboxes
  rescue StandardError => e
    Rails.logger.error "Failed to federate experience deletion #{experience_uri}: #{e.message}"
    # Let the job retry so the event isn’t silently dropped.
    raise
  end
end
