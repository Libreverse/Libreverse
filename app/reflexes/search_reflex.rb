# frozen_string_literal: true

class SearchReflex < ApplicationReflex
  def perform(_options = {})
      query = element[:value].to_s.strip
      query = query[0...50] # Cap the query length to 50 characters
      cache_key = "search/reflex/#{query}"

      log_info "[SearchReflex#perform] Processing search query: '#{query}'"

      @experiences = Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
        log_debug "[SearchReflex#perform] Cache miss for query: '#{query}', fetching from database"
        if query.present?
          Experience.where("title LIKE ?", "%#{sanitize_sql_like(query)}%")
                    .order(created_at: :desc)
                    .limit(100)
        else
          Experience.order(created_at: :desc).limit(20)
        end
      end

      log_info "[SearchReflex#perform] Found #{@experiences.size} experiences for query: '#{query}'"

      html_results = controller.render_to_string(partial: "search/experiences_list", locals: { experiences: @experiences })
      morph "#experiences_list", html_results
      log_debug "[SearchReflex#perform] Morph completed for #experiences_list"
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
    # Escape LIKE special characters: %, _, [, ], ^
    str.gsub(/[%_\[\]\^\\]/) { |x| "\\#{x}" }
  end
end
