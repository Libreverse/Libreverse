# frozen_string_literal: true

# Enhanced search service that searches both local experiences and indexed metaverse content
class UnifiedSearchService
  DEFAULT_LIMIT = 100
  METAVERSE_LIMIT_RATIO = 0.3 # 30% of results from metaverse content

  class << self
    # Main search method that combines local experiences and metaverse content
    def search(query, scope: nil, limit: DEFAULT_LIMIT, include_metaverse: true)
      query = query.to_s.strip
      return [] if query.blank?

      # Calculate split for results
      metaverse_limit = include_metaverse ? (limit * METAVERSE_LIMIT_RATIO).to_i : 0
      experience_limit = limit - metaverse_limit

      results = []

      # Search local experiences
      local_results = ExperienceSearchService.search(
        query,
        scope: scope,
        limit: experience_limit,
        use_vector_search: true
      )
      results.concat(local_results)

      # Search metaverse content if enabled
      if include_metaverse && metaverse_limit.positive?
        metaverse_results = search_metaverse_content(query, limit: metaverse_limit)
        results.concat(metaverse_results)
      end

      # Sort combined results by relevance/recency
      sort_unified_results(results, query)
    end

    # Search through indexed metaverse content
    def search_metaverse_content(query, limit: DEFAULT_LIMIT)
      # Simple text search through indexed content
      # This could be enhanced with vector search in the future
      indexed_content = IndexedContent.where(
        "title LIKE ? OR description LIKE ? OR author LIKE ?",
        "%#{sanitize_like(query)}%",
        "%#{sanitize_like(query)}%",
        "%#{sanitize_like(query)}%"
      ).limit(limit)

      indexed_content.to_a
    end

    # Search by platform
    def search_by_platform(platform, query: nil, limit: DEFAULT_LIMIT)
      scope = IndexedContent.where(source_platform: platform)

      if query.present?
        scope = scope.where(
          "title LIKE ? OR description LIKE ? OR author LIKE ?",
          "%#{sanitize_like(query)}%",
          "%#{sanitize_like(query)}%",
          "%#{sanitize_like(query)}%"
        )
      end

      scope.limit(limit).to_a
    end

    # Get popular content from each platform
    def featured_metaverse_content(limit_per_platform: 5)
      results = []

      # Get content from each platform
      platforms = IndexedContent.distinct.pluck(:source_platform)

      platforms.each do |platform|
        platform_content = IndexedContent
                           .where(source_platform: platform)
                           .order(created_at: :desc)
                           .limit(limit_per_platform)

        results.concat(platform_content.to_a)
      end

      results
    end

    private

    def sort_unified_results(results, _query)
      # Sort by a combination of relevance and recency
      # Local experiences get slight priority, then by created_at desc
      results.sort_by do |item|
        # Prioritize local content, then by recency
        priority = case item
        when Experience then 0
        when IndexedContent then 1
        else 2
        end

        # Use negative timestamp for descending order
        [ priority, -item.created_at.to_i ]
      end
    end

    def sanitize_like(str)
      ActiveRecord::Base.sanitize_sql_like(str)
    end
  end
end
