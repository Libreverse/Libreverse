# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

class ProcessSearchEmailJob < ApplicationJob
  queue_as :default

  def perform(sender_email:, sender_name:, query:, options:, original_message_id:)
    Rails.logger.info "[ProcessSearchEmailJob] Processing search: '#{query}' from #{sender_email}"

    # Validate query
    if query.blank?
      send_error_response(sender_email, "No search query provided")
      return
    end

    # Limit query length
    query = query[0...100]

    begin
      # Perform search using existing search service
      scope = Experience.approved # Email bot only searches approved experiences

      results = if options[:federated]
        FederatedExperienceSearchService.search_across_instances(
          query,
          limit: options[:limit]
        )
      else
        ExperienceSearchService.search(
          query,
          scope: scope,
          limit: options[:limit],
          use_vector_search: true
        )
      end

      # Send response
      SearchResultsMailer.search_results(
        sender_email,
        sender_name,
        query,
        results,
        options.merge(
          original_message_id: original_message_id,
          federated: options[:federated]
        )
      ).deliver_now

      Rails.logger.info "[ProcessSearchEmailJob] Sent #{results.size} results to #{sender_email}"
    rescue StandardError => e
      Rails.logger.error "[ProcessSearchEmailJob] Search failed: #{e.message}"
      send_error_response(sender_email, "Search temporarily unavailable")
    end
  end

  private

  def send_error_response(sender_email, error_message)
    SearchResultsMailer.error_response(sender_email, error_message).deliver_now
  end
end
