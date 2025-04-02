# frozen_string_literal: true

class SearchReflex < ApplicationReflex
  def perform
      query = element[:value].to_s.strip
      query = query[0...50] # Cap the query length to 50 characters
      cache_key = "search/reflex/#{query}"

      @experiences = Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
        if query.present?
          Experience.where("title LIKE ?", "%#{sanitize_sql_like(query)}%")
                    .order(created_at: :desc)
                    .limit(100)
        else
          Experience.order(created_at: :desc).limit(20)
        end
      end

      # Morph the experiences_list div with the new content
      morph "#experiences_list", ApplicationController.render(
        partial: "search/experiences_list",
        locals: { experiences: @experiences }
      )
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
