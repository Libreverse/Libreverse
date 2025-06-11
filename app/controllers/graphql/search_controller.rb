# frozen_string_literal: true

module Graphql
  class SearchController < GraphqlApplicationController
    model("Experience")

    # Queries
    action(:experiences).permit(query: "String", limit: "Int").returns("[Experience!]!")

    def experiences
      query = params[:query]
      limit = [ params[:limit] || 20, 100 ].min

      scope = if current_account&.admin?
        Experience
      else
        Experience.approved
      end

      if query.present?
        # Limit query length and sanitize
        query = query.to_s.strip[0...50]

        # Use vector similarity search with fallback to LIKE search
        search_results = ExperienceSearchService.search(
          query,
          scope: scope,
          limit: limit,
          use_vector_search: true
        )

        # Extract experiences from search results
        search_results.map { |result| result[:experience] }
      else
        scope.order(created_at: :desc).limit(limit)
      end
    end
  end
end
