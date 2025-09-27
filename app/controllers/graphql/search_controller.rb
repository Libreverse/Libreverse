module Graphql
  class SearchController < GraphqlApplicationController
    model("Experience")

    # Queries
    action(:experiences).permit(query: "String", limit: "Int").returns("[Experience!]!")

    def experiences
      query = params[:query]
      limit_param = params[:limit].presence&.to_i || 20
      limit       = [ limit_param, 100 ].min

      scope = if current_account&.admin?
        Experience
      else
        Experience.approved
      end

      if query.present?
        # Limit query length and sanitize
        query = query.to_s.strip[0...50]

        # Use vector similarity search with fallback to LIKE search
        ExperienceSearchService.search(
          query,
          scope: scope,
          limit: limit,
          use_vector_search: true
        )

        # search_results are already Experience objects

      else
        scope.order(created_at: :desc).limit(limit)
      end
    end
  end
end
