# frozen_string_literal: true
# shareable_constant_value: literal

class BatchVectorizeExperiencesJob < ApplicationJob
  queue_as :default

  # This job may take a while for large numbers of experiences
  retry_on StandardError, wait: 5.seconds, attempts: 2

  def perform(batch_size: 50, force_regeneration: false, approved_only: false)
    Rails.logger.info "[BatchVectorizeExperiencesJob] Starting batch vectorization"

    scope = approved_only ? Experience.approved : Experience.all
    total_experiences = scope.count

    scope_description = approved_only ? "approved experiences" : "all experiences"
    Rails.logger.info "[BatchVectorizeExperiencesJob] Processing #{total_experiences} #{scope_description} in batches of #{batch_size}"

    processed = 0
    errors = 0
    skipped = 0

    scope.find_in_batches(batch_size: batch_size) do |experiences|
      experiences.each do |experience|
          existing_vector = experience.experience_vector

          # Skip if vector exists and is up to date (unless forcing regeneration)
          if existing_vector && !force_regeneration && !existing_vector.needs_regeneration?(experience)
            skipped += 1
            next
          end

          # Queue individual vectorization job
          VectorizeExperienceJob.perform_later(experience.id, force_regeneration: force_regeneration)
          processed += 1
      rescue StandardError => e
          Rails.logger.error "[BatchVectorizeExperiencesJob] Error processing experience #{experience.id}: #{e.message}"
          errors += 1
      end

      # Log progress
      completion_percentage =
        if total_experiences.zero?
  100.0
        else
  (((processed + errors + skipped).to_f / total_experiences) * 100).round(1)
        end
      Rails.logger.info "[BatchVectorizeExperiencesJob] Progress: #{completion_percentage}% (#{processed} queued, #{skipped} skipped, #{errors} errors)"
    end

    # Refresh vocabulary cache after batch processing
    VectorizationService.refresh_vocabulary

    Rails.logger.info "[BatchVectorizeExperiencesJob] Completed: #{processed} experiences queued for vectorization, #{skipped} skipped, #{errors} errors"
  end
end
