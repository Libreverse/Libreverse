# frozen_string_literal: true

class GenerateEmbeddingJob < ApplicationJob
  queue_as :default

  def perform(experience_id)
    Rails.logger.info "GenerateEmbeddingJob: Processing experience ID #{experience_id}"

    experience = Experience.find_by(id: experience_id)
    unless experience
      Rails.logger.warn "GenerateEmbeddingJob: Experience #{experience_id} not found"
      return
    end

    Rails.logger.info "GenerateEmbeddingJob: Generating embedding for '#{experience.title}'"
    VectorSearchService.update_experience_embedding(experience)
    Rails.logger.info "GenerateEmbeddingJob: Successfully generated embedding for experience #{experience_id}"
  rescue StandardError => e
    Rails.logger.error "GenerateEmbeddingJob: Failed to generate embedding for experience #{experience_id}: #{e.message}"
    Rails.logger.error "GenerateEmbeddingJob: Backtrace: #{e.backtrace.first(5).join("\n")}"
    raise # Re-raise to trigger retry mechanism
  end
end
