# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class VectorEmbeddingService
  # Default embedding dimensions (adjust based on requirements)
  DEFAULT_DIMENSIONS = 384

  class EmbeddingError < StandardError; end

  class << self
    # Generate embedding for given text fields
    # For now, this uses a simple TF-IDF approach but can be upgraded to use proper embeddings
    def generate_embedding(title, description, author)
        # Combine all text fields
        combined_text = [ title, description, author ].compact.join(" ")

        # Fallback to simple approach if combined text is empty
        return fallback_embedding if combined_text.strip.empty?

        # Use the existing vectorization service for now
        # This creates a basic embedding based on TF-IDF
        create_text_embedding(combined_text)
    rescue StandardError => e
        Rails.logger.error "[VectorEmbeddingService] Failed to generate embedding: #{e.message}"
        raise EmbeddingError, "Failed to generate embedding: #{e.message}"
    end

    # Generate embedding specifically for IndexedContent
    def generate_for_indexed_content(indexed_content)
      generate_embedding(
        indexed_content.title,
        indexed_content.description,
        indexed_content.author
      )
    end

    private

    # Create a text-based embedding using TF-IDF and hashing
    def create_text_embedding(text)
      # Preprocess the text
      terms = TextPreprocessingService.preprocess(text)

      # Create a vocabulary from common terms
      vocabulary = base_vocabulary

      # Calculate term frequencies
      term_frequencies = calculate_term_frequencies(terms)

      # Generate a fixed-size vector
      vector = vocabulary.map do |term|
        freq = term_frequencies[term] || 0.0
        # Apply some basic TF-IDF-like transformation
        freq.positive? ? Math.log(1 + freq) : 0.0
      end

      # Pad or truncate to desired dimensions
      adjust_vector_size(vector)
    end

    # Calculate simple term frequencies
    def calculate_term_frequencies(terms)
      return {} if terms.empty?

      term_counts = Hash.new(0)
      terms.each { |term| term_counts[term] += 1 }

      # Normalize by document length
      max_count = term_counts.values.max.to_f
      return {} if max_count.zero?

      term_counts.transform_values { |count| count / max_count }
    end

    # Get base vocabulary for embedding generation
    def base_vocabulary
      Rails.cache.fetch("embedding_vocabulary", expires_in: 24.hours) do
        create_base_vocabulary
      end
    end

    # Create a base vocabulary from common terms
    def create_base_vocabulary
      # For metaverse content, include relevant terms
      base_terms = %w[
        virtual world metaverse scene game experience interactive
        avatar player user social multiplayer online digital
        environment landscape building architecture art music
        event meeting conference exhibition gallery shop store
        vr ar web3 blockchain nft decentraland sandbox
        explore adventure quest challenge puzzle educational
        creative artistic immersive realistic fantasy sci-fi
        community collaboration networking entertainment fun
      ]

      # If we have indexed content, add terms from actual content
      if IndexedContent.exists?
        content_terms = extract_content_terms
        base_terms.concat(content_terms)
      end

      # Ensure we have exactly the right number of dimensions
      base_terms.uniq.first(DEFAULT_DIMENSIONS - 50) # Leave room for padding
    end

    # Extract common terms from existing indexed content
    def extract_content_terms
      all_text = IndexedContent.limit(100).pluck(:title, :description).flatten.compact.join(" ")
      terms = TextPreprocessingService.preprocess(all_text)

      # Get most frequent terms
      term_counts = Hash.new(0)
      terms.each { |term| term_counts[term] += 1 }

      term_counts.sort_by { |_, count| -count }
                 .first(100)
                 .map(&:first)
    end

    # Adjust vector to desired dimensions
    def adjust_vector_size(vector)
      current_size = vector.length
      target_size = DEFAULT_DIMENSIONS

      if current_size >= target_size
        # Truncate
        vector.first(target_size)
      else
        # Pad with zeros
        vector + Array.new(target_size - current_size, 0.0)
      end
    end

    # Fallback embedding for empty content
    def fallback_embedding
      Array.new(DEFAULT_DIMENSIONS, 0.01) # Small non-zero values
    end
  end
end
