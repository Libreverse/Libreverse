# frozen_string_literal: true

class SearchReflex < ApplicationReflex
  def perform
    begin
      query = element[:value].to_s.strip
      query = query[0...50] # Cap the query length to 50 characters
      cache_key = "search/reflex/#{query}"

      @experiences = Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
        if query.present?
          Experience.where("title LIKE ?", "%#{query}%")
                    .order(created_at: :desc)
        else
          Experience.all.order(created_at: :desc)
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
    rescue => e
      Rails.logger.error "Search reflex error: #{e.message}"
      morph :nothing
    end
  end
end
