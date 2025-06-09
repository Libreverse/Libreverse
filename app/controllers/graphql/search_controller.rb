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
        # Limit query length and use VSS search
        query = query.to_s.strip[0...50]
        VectorSearchService.search_similar_experiences(query, limit: limit)
      else
        scope.order(created_at: :desc).limit(limit)
      end
    end
  end
end
