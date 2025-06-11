# frozen_string_literal: true

class VectorSimilarityService
  class << self
    # Calculate cosine similarity between two vectors
    def cosine_similarity(vector_a, vector_b)
      return 0.0 if vector_a.nil? || vector_b.nil? || vector_a.empty? || vector_b.empty?
      return 0.0 if vector_a.length != vector_b.length

      dot_product = 0.0
      magnitude_a = 0.0
      magnitude_b = 0.0

      # Use while loop instead of each_with_index for better performance
      i = 0
      while i < vector_a.length
        a = vector_a[i]
        b = vector_b[i]
        dot_product += a * b
        magnitude_a += a * a
        magnitude_b += b * b
        i += 1
      end

      return 0.0 if magnitude_a == 0.0 || magnitude_b == 0.0

      dot_product / (Math.sqrt(magnitude_a) * Math.sqrt(magnitude_b))
    end

    # Find experiences similar to a query vector
    def find_similar_experiences(query_vector, scope = nil, limit: 50, threshold: 0.01)
      scope ||= Experience.approved

      # Get all experience vectors
      experience_vectors = ExperienceVector.joins(:experience)
                                           .where(experience: scope)
                                           .includes(:experience)

      # Calculate similarities
      similarities = []

      experience_vectors.find_each do |exp_vector|
        similarity = cosine_similarity(query_vector, exp_vector.vector_data)

        if similarity > threshold
          similarities << {
            experience: exp_vector.experience,
            similarity: similarity,
            experience_vector: exp_vector
          }
        end
      end

      # Sort by similarity (descending) and apply limit
      similarities.sort_by { |item| -item[:similarity] }
                  .first(limit)
    end

    # Find experiences similar to another experience
    def find_similar_to_experience(target_experience, limit: 20, threshold: 0.1)
      target_vector = target_experience.experience_vector&.vector_data
      return [] unless target_vector

      scope = Experience.approved.where.not(id: target_experience.id)
      find_similar_experiences(target_vector, scope, limit: limit, threshold: threshold)
    end

    # Batch similarity calculation for multiple queries
    def batch_similarity(query_vectors, experience_vectors)
      results = []

      # Use while loop instead of each_with_index for better performance
      query_index = 0
      while query_index < query_vectors.length
        query_vector = query_vectors[query_index]
        query_results = []

        experience_vectors.each do |exp_vector|
          similarity = cosine_similarity(query_vector, exp_vector.vector_data)
          query_results << {
            experience: exp_vector.experience,
            similarity: similarity
          }
        end

        results << query_results.sort_by { |item| -item[:similarity] }
        query_index += 1
      end

      results
    end

    # Calculate vector magnitude (length)
    def vector_magnitude(vector)
      return 0.0 if vector.blank?

      Math.sqrt(vector.sum { |component| component * component })
    end

    # Normalize a vector to unit length
    def normalize_vector(vector)
      magnitude = vector_magnitude(vector)
      return vector if magnitude == 0.0

      vector.map { |component| component / magnitude }
    end

    # Calculate Euclidean distance between vectors
    def euclidean_distance(vector_a, vector_b)
      return Float::INFINITY if vector_a.nil? || vector_b.nil? || vector_a.length != vector_b.length

      sum_of_squares = 0.0
      # Use while loop instead of each_with_index for better performance
      i = 0
      while i < vector_a.length
        diff = vector_a[i] - vector_b[i]
        sum_of_squares += diff * diff
        i += 1
      end

      Math.sqrt(sum_of_squares)
    end

    # Calculate Manhattan distance between vectors
    def manhattan_distance(vector_a, vector_b)
      return Float::INFINITY if vector_a.nil? || vector_b.nil? || vector_a.length != vector_b.length

      distance = 0.0
      # Use while loop instead of each_with_index for better performance
      i = 0
      while i < vector_a.length
        distance += (vector_a[i] - vector_b[i]).abs
        i += 1
      end

      distance
    end
  end
end
