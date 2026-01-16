# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

require "memo_wise"

class ExperienceSearchService
  # Minimum similarity threshold for results
  DEFAULT_SIMILARITY_THRESHOLD = 0.0

  # Maximum number of results to return
  DEFAULT_LIMIT = 100

  class << self
    prepend MemoWise
    # Main search method that handles both vector and fallback search
    def search(query, scope: nil, limit: DEFAULT_LIMIT, use_vector_search: true, include_metaverse: true)
      query = query.to_s.strip
      return [] if query.blank?

      scope ||= Experience.approved

      # Split the limit between experiences and metaverse content
      metaverse_limit = include_metaverse ? (limit * 0.3).to_i : 0
      experience_limit = limit - metaverse_limit

      results = []

      # Search local experiences
      experience_results = search_experiences(query, scope: scope, limit: experience_limit, use_vector_search: use_vector_search)
      results.concat(experience_results)

      # Search metaverse content if enabled
      if include_metaverse && metaverse_limit.positive?
        metaverse_results = search_metaverse_content(query, limit: metaverse_limit, use_vector_search: use_vector_search)
        results.concat(metaverse_results)
      end

      # Sort combined results by relevance
      results.sort_by { |item| -(item.is_a?(Experience) ? 1 : 0) } # Prioritize local experiences slightly
    end

    # Search only experiences
    def search_experiences(query, scope: nil, limit: DEFAULT_LIMIT, use_vector_search: true)
      query = query.to_s.strip
      return [] if query.blank?

      scope ||= Experience.approved

      # Try vector search first if enabled and vectors exist
      if use_vector_search && vectors_available?
        begin
          vector_results = vector_search(query, scope: scope, limit: limit)

          # Extract experiences from vector search results
          results = vector_results.map { |result| result[:experience] }

          # Fall back to LIKE search if no vector results
          if results.empty?
            Rails.logger.info "[ExperienceSearchService] Vector search returned no results, falling back to LIKE search"
            like_results = like_search(query, scope: scope, limit: limit)
            results = like_results.map { |result| result[:experience] }
          end
        rescue StandardError => e
          Rails.logger.warn "[ExperienceSearchService] Vector search failed: #{e.message}, falling back to LIKE search"
          like_results = like_search(query, scope: scope, limit: limit)
          results = like_results.map { |result| result[:experience] }
        end

        results
      else
        # Use traditional LIKE search
        like_results = like_search(query, scope: scope, limit: limit)
        like_results.map { |result| result[:experience] }
      end
    end

    # Vector-based similarity search
    def vector_search(query, scope: nil, limit: DEFAULT_LIMIT, threshold: DEFAULT_SIMILARITY_THRESHOLD)
      scope ||= Experience.approved

      begin
        # Generate query vector
        query_vector = VectorizationService.vectorize_query(query)

        # Find similar experiences
        similarities = VectorSimilarityService.find_similar_experiences(
          query_vector,
          scope,
          limit: limit,
          threshold: threshold
        )

        # Apply hybrid ranking (similarity + recency + other factors)
        ranked_results = apply_hybrid_ranking(similarities, query)

        # Return experiences with metadata
        ranked_results.map do |result|
          {
            experience: result[:experience],
            similarity: result[:similarity],
            rank_score: result[:rank_score],
            search_type: :vector
          }
        end
      rescue StandardError => e
        Rails.logger.error "[ExperienceSearchService] Vector search failed: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        []
      end
    end

    # Traditional LIKE search as fallback
    def like_search(query, scope: nil, limit: DEFAULT_LIMIT)
      scope ||= Experience.approved

      # Sanitize query for SQL LIKE
      sanitized_query = ActiveRecord::Base.sanitize_sql_like(query)

      # Search across multiple fields with different weights
      results = scope.where(
        "title LIKE ? OR description LIKE ? OR author LIKE ?",
        "%#{sanitized_query}%",
        "%#{sanitized_query}%",
        "%#{sanitized_query}%"
      ).order(created_at: :desc)
                     .limit(limit)

      # Convert to consistent format
      results.map do |experience|
        {
          experience: experience,
          similarity: calculate_like_similarity(experience, query),
          rank_score: 0.5, # Default rank score for LIKE results
          search_type: :like
        }
      end
    end

    # Search metaverse content (IndexedContent)
    def search_metaverse_content(query, limit: DEFAULT_LIMIT, use_vector_search: true)
      # Try vector search first if available
      if use_vector_search && metaverse_vectors_available?
        begin
          vector_results = metaverse_vector_search(query, limit: limit)
          return vector_results unless vector_results.empty?
        rescue StandardError => e
          Rails.logger.warn "[ExperienceSearchService] Metaverse vector search failed: #{e.message}, falling back to LIKE search"
        end
      end

      # Fall back to LIKE search
      metaverse_like_search(query, limit: limit)
    end

    # Vector search for metaverse content
    def metaverse_vector_search(query, limit: DEFAULT_LIMIT)
        # Generate query vector
        query_vector = VectorizationService.vectorize_query(query)

        # Find similar indexed content vectors
        indexed_content_vectors = IndexedContentVector.includes(:indexed_content)

        results = indexed_content_vectors.map do |vector|
          similarity = vector.cosine_similarity(query_vector)
          next if similarity < DEFAULT_SIMILARITY_THRESHOLD

          {
            content: vector.indexed_content,
            similarity: similarity,
            search_type: :vector
          }
        end.compact

        # Sort by similarity and limit results
        results.sort_by { |r| -r[:similarity] }.first(limit).map { |r| r[:content] }
    rescue StandardError => e
        Rails.logger.error "[ExperienceSearchService] Metaverse vector search error: #{e.message}"
        []
    end

    # LIKE search for metaverse content
    def metaverse_like_search(query, limit: DEFAULT_LIMIT)
      sanitized_query = ActiveRecord::Base.sanitize_sql_like(query)

      IndexedContent.where(
        "title LIKE ? OR description LIKE ? OR author LIKE ?",
        "%#{sanitized_query}%",
        "%#{sanitized_query}%",
        "%#{sanitized_query}%"
      ).order(created_at: :desc).limit(limit)
    end

    # Check if vector search is available
    def vectors_available?
      return false unless ExperienceVector.exists?

      begin
        vocabulary = VectorizationService.current_vocabulary
        vocabulary.is_a?(Array) && vocabulary.any?
      rescue StandardError => e
        Rails.logger.warn "Error checking vocabulary availability: #{e.message}"
        false
      end
    end

    # Check if metaverse vectors are available
    def metaverse_vectors_available?
      IndexedContentVector.exists?
    end

    # Get search suggestions based on query
    def suggest(query, limit: 5)
      query = query.to_s.strip.downcase
      return [] if query.length < 2

      # Find experiences with titles starting with or containing the query
      suggestions = Experience.approved
                              .where("LOWER(title) LIKE ?", "#{query}%")
                              .limit(limit)
                              .pluck(:title)

      # If not enough suggestions, try broader search
      if suggestions.length < limit
        broader_suggestions = Experience.approved
                                        .where("LOWER(title) LIKE ? AND LOWER(title) NOT LIKE ?",
                                               "%#{query}%", "#{query}%")
                                        .limit(limit - suggestions.length)
                                        .pluck(:title)
        suggestions += broader_suggestions
      end

      suggestions.uniq
    end

    # Find related experiences for a given experience
    def find_related(experience, limit: 10)
      if vectors_available? && experience.experience_vector
        similarities = VectorSimilarityService.find_similar_to_experience(
          experience,
          limit: limit,
          threshold: 0.1
        )

        similarities.map { |result| result[:experience] }
      else
        # Fallback: find by same author or similar title words
        fallback_related_search(experience, limit)
      end
    end

    private

    # Apply hybrid ranking combining similarity with other factors
    def apply_hybrid_ranking(similarities, query)
      ranked_results = similarities.map do |result|
        experience = result[:experience]
        similarity = result[:similarity]

        # Calculate additional ranking factors
        recency_score = calculate_recency_score(experience)
        title_match_score = calculate_title_match_score(experience, query)

        # Combine scores (weighted)
        rank_score = (similarity * 0.7) + (recency_score * 0.2) + (title_match_score * 0.1)

        result.merge(rank_score: rank_score)
      end

      # Sort by rank score (separate from the map block to avoid multiline chain)
      ranked_results.sort_by { |result| -result[:rank_score] }
    end

    # Calculate recency score (newer = higher score)
    def calculate_recency_score(experience)
      days_ago = (Time.current - experience.created_at) / 1.day

      # Exponential decay: score decreases as content gets older
      Math.exp(-days_ago / 365.0) # Half-life of about 1 year
    end
    memo_wise :calculate_recency_score

    # Calculate how well the query matches the title
    def calculate_title_match_score(experience, query)
      return 0.0 if experience.title.blank? || query.blank?

      title_words = experience.title.downcase.split
      query_words = query.downcase.split

      # Calculate word overlap
      overlap = (title_words & query_words).length
      total_unique = (title_words | query_words).length

      return 0.0 if total_unique.zero?

      overlap.to_f / total_unique
    end
    memo_wise :calculate_title_match_score

    # Calculate similarity score for LIKE search results
    def calculate_like_similarity(experience, query)
      # Simple scoring based on where the match occurs
      query_lower = query.downcase

      score = 0.0

      # Title match (highest weight)
      if experience.title&.downcase&.include?(query_lower)
        score += if experience.title.downcase.start_with?(query_lower)
          1.0
        else
          0.7
        end
      end

      # Description match (medium weight)
      score += 0.5 if experience.description&.downcase&.include?(query_lower)

      # Author match (lower weight)
      score += 0.3 if experience.author&.downcase&.include?(query_lower)

      # Normalize to 0-1 range
      [ score / 1.8, 1.0 ].min
    end
    memo_wise :calculate_like_similarity

    # Fallback method for finding related experiences
    def fallback_related_search(experience, limit)
      related = []

      # Find by same author
      if experience.author.present?
        related += Experience.approved
                             .where(author: experience.author)
                             .where.not(id: experience.id)
                             .limit(limit / 2)
      end

      # Find by similar title words if we need more
      if related.length < limit && experience.title.present?
        title_words = experience.title.split.map(&:downcase).reject { |w| w.length < 3 }

        if title_words.any?
          # Build a query for experiences containing any of the title words
          conditions = title_words.map { "LOWER(title) LIKE ?" }.join(" OR ")
          values = title_words.map { |word| "%#{word}%" }

          similar_titles = Experience.approved
                                     .where(conditions, *values)
                                     .where.not(id: experience.id)
                                     .where.not(id: related.map(&:id))
                                     .limit(limit - related.length)

          related += similar_titles
        end
      end

      related.first(limit)
    end
  end
end
