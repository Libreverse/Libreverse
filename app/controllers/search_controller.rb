# frozen_string_literal: true

require "re2"
require "digest"

# app/controllers/search_controller.rb
class SearchController < ApplicationController
  skip_before_action :global_spam_protection_check
  before_action :set_cache_headers_for_search

  def index
    # Ensure query is a string and handle nil/malformed queries gracefully
    query = params[:query].is_a?(String) ? params[:query].strip : ""
    query = query[0...50]
    # Generate ETag before expensive database query
    user_role = current_account&.admin? ? "admin" : "user"
    query_hash = query.present? ? Digest::MD5.hexdigest(query) : "empty"

    # For search, we could use a simpler cache key without exact count/timestamp
    # since search results can tolerate some staleness
    cache_key = "search/#{user_role}/#{query_hash}/#{Time.current.beginning_of_minute.to_i}"
    etag_value = %("#{Digest::MD5.hexdigest(cache_key)}")

    # Handle conditional requests before database query
    if !Rails.env.development? && request.headers["If-None-Match"] == etag_value
      head :not_modified
      return
    end

    scope = current_account&.admin? ? Experience : Experience.approved

    if query.present?
      begin
        # Check if federated search is requested
        if params[:federated] == "true"
          # Use federated search across instances with unified interface
          search_results = FederatedExperienceSearchService.search_across_instances(
            query,
            limit: 50
          )

          # Convert to unified experiences for consistent UI treatment
          @experiences = UnifiedExperience.from_search_results(search_results)
          @search_metadata = {
            total_results: @experiences.length,
            search_type: :federated,
            query: query,
            federated: true
          }
        else
          # Use local search with unified experience interface
          local_results = ExperienceSearchService.search(
            query,
            scope: scope,
            limit: 100,
            use_vector_search: true
          )

          # Convert to unified experiences for consistent UI treatment
          @experiences = UnifiedExperience.from_search_results(local_results)

          # Store search metadata for potential display
          @search_metadata = {
            total_results: @experiences.length,
            search_type: :vector, # Default to vector since ExperienceSearchService handles fallback internally
            query: query,
            federated: false
          }
        end
      rescue StandardError => e
        Rails.logger.error "Search failed for query '#{query}': #{e.message}"
        @experiences = []
        @search_metadata = {
          total_results: 0,
          search_type: :error,
          query: query,
          error_message: "Search temporarily unavailable"
        }
      end
    else
      # No query - show recent local experiences as unified experiences
      recent_experiences = scope.order(created_at: :desc).limit(20)
      @experiences = UnifiedExperience.from_search_results(recent_experiences)
      @search_metadata = { total_results: @experiences.length, search_type: :recent }
    end

    # Handle conditional requests for all search results
    # Handle conditional requests (skip in development to avoid masking errors)
    return if Rails.env.development?

      response.headers["ETag"] = etag_value
      head :not_modified if request.headers["If-None-Match"] == etag_value

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
