class VectorizeExperienceJob < ApplicationJob
  queue_as :default

  # Retry configuration
  retry_on StandardError, wait: 5.seconds, attempts: 3

  def perform(experience_id, force_regeneration: false)
    experience = Experience.find_by(id: experience_id)

    unless experience
      Rails.logger.warn "[VectorizeExperienceJob] Experience #{experience_id} not found"
      return
    end

    # Vectorize ALL experiences, regardless of approval status
    # This enables comprehensive search and better admin/moderator tools

    existing_vector = experience.experience_vector

    # Check if regeneration is needed
    if existing_vector && !force_regeneration && !existing_vector.needs_regeneration?(experience)
        Rails.logger.info "[VectorizeExperienceJob] Vector for experience #{experience_id} is up to date"
        return
    end

    Rails.logger.info "[VectorizeExperienceJob] Generating vector for experience #{experience_id}"

    begin
      # Generate the vector
      vector_data = VectorizationService.vectorize_experience(experience)

      # Calculate content hash for change detection
      content_hash = ExperienceVector.generate_content_hash(
        experience.title,
        experience.description,
        experience.author
      )

      if existing_vector
        existing_vector.with_lock do
          existing_vector.update!(
            vector_data: vector_data,
            vector_hash: content_hash,
            generated_at: Time.current,
            version: existing_vector.version + 1
          )
        end
        Rails.logger.info "[VectorizeExperienceJob] Updated vector for experience #{experience_id}"
      else
        ExperienceVector.create!(
          experience: experience,
          vector_data: vector_data,
          vector_hash: content_hash,
          generated_at: Time.current,
          version: 1
        )
        Rails.logger.info "[VectorizeExperienceJob] Created vector for experience #{experience_id}"
      end

      # Clear related caches
      clear_search_caches
    rescue StandardError => e
      Rails.logger.error "[VectorizeExperienceJob] Failed to vectorize experience #{experience_id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end

  private

  def clear_search_caches
    # Clear vocabulary and document frequency caches
    Rails.cache.delete("search_vocabulary")
    Rails.cache.delete("document_frequencies")

    # NOTE: SolidCache doesn't support delete_matched, so we skip search result cache clearing
    Rails.logger.info "[VectorizeExperienceJob] Cleared vocabulary and document frequency caches"
  end
end
