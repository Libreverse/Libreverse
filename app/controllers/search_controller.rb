# frozen_string_literal: true

require "re2"
require "digest"

# app/controllers/search_controller.rb
class SearchController < ApplicationController
  before_action :set_cache_headers_for_search

  def index
    query = params[:query].to_s.strip
    # Cap query length and validate input
    query = query[0...50]
    # Generate ETag before expensive database query
    user_role = current_account&.admin? ? "admin" : "user"
    query_hash = query.present? ? Digest::MD5.hexdigest(query) : "empty"

    # For search, we could use a simpler cache key without exact count/timestamp
    # since search results can tolerate some staleness
    cache_key = "search/#{user_role}/#{query_hash}/#{Time.current.beginning_of_minute.to_i}"
    etag = Digest::MD5.hexdigest(cache_key)

    # Handle conditional requests before database query
    return if !Rails.env.development? && request.fresh?(etag: etag)

    scope = current_account&.admin? ? Experience : Experience.approved

    if query.present?
      # Use vector similarity search with fallback to LIKE search
      search_results = ExperienceSearchService.search(
        query,
        scope: scope,
        limit: 100,
        use_vector_search: true
      )

      # Search results are now Experience objects directly (not hashes)
      @experiences = search_results

      # Store search metadata for potential display
      @search_metadata = {
        total_results: search_results.length,
        search_type: :vector, # Default to vector since ExperienceSearchService handles fallback internally
        query: query
      }
    else
      # No query - show recent experiences
      @experiences = scope.order(created_at: :desc).limit(20)
      @search_metadata = { total_results: @experiences.length, search_type: :recent }
    end

    # Handle conditional requests for all search results
    # Handle conditional requests (skip in development to avoid masking errors)
    return if Rails.env.development?

      nil unless stale?(etag: etag, public: false)

    # Content has changed or no ETag in request, proceed with rendering
  end

  private

  def set_cache_headers_for_search
    # Cache search results for 2 minutes - balance between freshness and performance
    # Skip cache headers in development to avoid masking application errors
    expires_in 2.minutes, public: false unless Rails.env.development?
  end

  # Sanitize SQL LIKE wildcards to prevent injection
  def sanitize_sql_like(str)
    ActiveRecord::Base.sanitize_sql_like(str)
  end
end
