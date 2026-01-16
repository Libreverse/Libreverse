# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class SearchReflex < ApplicationReflex
  def perform(_options = {})
      query = element[:value].to_s.strip
      query = query[0...50] # Cap the query length to 50 characters
      role_suffix = current_account&.admin? ? "admin" : "public"
cache_key = "search/reflex/#{role_suffix}/#{query}"

      log_info "[SearchReflex#perform] Processing search query: '#{query}'"

      @experiences = Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
        log_debug "[SearchReflex#perform] Cache miss for query: '#{query}', fetching from database"

        scope = current_account&.admin? ? Experience : Experience.approved
        if query.present?
          # Determine scope based on user permissions (like SearchController)

          # Use vector similarity search with fallback to LIKE search
          search_results = ExperienceSearchService.search(
            query,
            scope: scope,
            limit: 100,
            use_vector_search: true
          )

          # Convert to unified experiences for consistent UI treatment
          UnifiedExperience.from_search_results(search_results)
        else
          # Same scope logic for empty query - convert to unified experiences
          recent_experiences = scope.order(created_at: :desc).limit(20)
          UnifiedExperience.from_search_results(recent_experiences)
        end
      end

      log_info "[SearchReflex#perform] Found #{@experiences.size} experiences for query: '#{query}'"

      html_results = controller.render_to_string(partial: "search/experiences_list", locals: { experiences: @experiences })
      morph "#experiences-list", html_results
      log_debug "[SearchReflex#perform] Morph completed for #experiences-list"
  rescue ActionController::RoutingError => e
      Rails.logger.warn "Search reflex routing error: #{e.message}"
      morph :nothing
  rescue StandardError => e
      Rails.logger.error "Search reflex error: #{e.message}"
      morph :nothing
  end

  private

  # Sanitize SQL LIKE wildcards to prevent injection
  def sanitize_sql_like(str)
    ActiveRecord::Base.sanitize_sql_like(str)
  end
end
