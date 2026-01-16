# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

class VectorizeIndexedContentJob < ApplicationJob
  queue_as :default

  # Retry configuration
  retry_on StandardError, wait: 5.seconds, attempts: 3

  def perform(indexed_content_id, force_regeneration: false)
    indexed_content = IndexedContent.find_by(id: indexed_content_id)

    unless indexed_content
      Rails.logger.warn "[VectorizeIndexedContentJob] IndexedContent #{indexed_content_id} not found"
      return
    end

    existing_vector = indexed_content.indexed_content_vector

    # Check if regeneration is needed
    if existing_vector && !force_regeneration && !existing_vector.needs_regeneration?(indexed_content)
      Rails.logger.info "[VectorizeIndexedContentJob] Vector for indexed_content #{indexed_content_id} is up to date"
      return
    end

    Rails.logger.info "[VectorizeIndexedContentJob] Generating vector for indexed_content #{indexed_content_id}"

    begin
      # Generate embedding for the content
      vector_data = VectorEmbeddingService.generate_embedding(
        indexed_content.title,
        indexed_content.description,
        indexed_content.author
      )

      # Ensure we have valid vector data
      if vector_data.blank? || !vector_data.is_a?(Array)
        Rails.logger.error "[VectorizeIndexedContentJob] Invalid vector data generated for indexed_content #{indexed_content_id}"
        return
      end

      # Calculate content hash for change detection
      content_hash = IndexedContentVector.generate_content_hash(
        indexed_content.title,
        indexed_content.description,
        indexed_content.author
      )

      # Ensure content_hash is not nil
      if content_hash.blank?
        Rails.logger.error "[VectorizeIndexedContentJob] Failed to generate content hash for indexed_content #{indexed_content_id}"
        return
      end

      # Generate vector hash from the actual vector data
      vector_hash = Digest::MD5.hexdigest(vector_data.to_json)

      if existing_vector
        # Update existing vector
        existing_vector.update!(
          vector_data: vector_data,
          vector_hash: vector_hash,
          content_hash: content_hash,
          generated_at: Time.current
        )
        Rails.logger.info "[VectorizeIndexedContentJob] Updated vector for indexed_content #{indexed_content_id}"
      else
        # Create new vector
        IndexedContentVector.create!(
          indexed_content: indexed_content,
          vector_data: vector_data,
          vector_hash: vector_hash,
          content_hash: content_hash,
          generated_at: Time.current
        )
        Rails.logger.info "[VectorizeIndexedContentJob] Created vector for indexed_content #{indexed_content_id}"
      end
    rescue VectorEmbeddingService::EmbeddingError => e
      Rails.logger.error "[VectorizeIndexedContentJob] Embedding generation failed for indexed_content #{indexed_content_id}: #{e.message}"
      raise e
    rescue StandardError => e
      Rails.logger.error "[VectorizeIndexedContentJob] Vectorization failed for indexed_content #{indexed_content_id}: #{e.message}"
      raise e
    end
  end
end
