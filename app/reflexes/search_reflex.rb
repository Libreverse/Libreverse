# frozen_string_literal: true

class SearchReflex < ApplicationReflex
  def perform(options = {})
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
      
      # Update the URL if requested
      if options[:updateUrl]
        update_url(query)
      end
  rescue ActionController::RoutingError => e
      Rails.logger.warn "Search reflex routing error: #{e.message}"
      morph :nothing
  rescue StandardError => e
      Rails.logger.error "Search reflex error: #{e.message}"
      morph :nothing
  end

  private

  # Update the URL in the browser using CableReady
  def update_url(query)
    url = request.url
    uri = URI(url)
    params = URI.decode_www_form(uri.query || "").to_h
    
    if query.blank?
      params.delete("query")
    else
      params["query"] = query
    end
    
    uri.query = URI.encode_www_form(params) unless params.empty?
    new_url = uri.to_s
    
    cable_ready
      .push_state(
        url: new_url,
        title: "Search Results"
      )
      .broadcast
  end

  # Sanitize SQL LIKE wildcards to prevent injection
  def sanitize_sql_like(str)
    # Escape LIKE special characters: %, _, [, ], ^
    str.gsub(/[%_\[\]\^\\]/) { |x| "\\#{x}" }
  end
end
