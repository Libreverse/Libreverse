# frozen_string_literal: true
# shareable_constant_value: literal

class SearchResultsMailer < ApplicationMailer
  def search_results(sender_email, sender_name, query, results, options = {})
    @sender_name = sender_name
    @query = query
    @results = format_results(results)
    @total_results = @results.size
    @federated = options[:federated] || false
    @instance_domain = LibreverseInstance.instance_domain

    # Set up response headers
    headers = {
      to: sender_email,
      subject: "Search results for '#{query}'"
    }

    # Add In-Reply-To header if we have original message ID
    if options[:original_message_id].present?
      headers["In-Reply-To"] = options[:original_message_id]
      headers["References"] = options[:original_message_id]
    end

    # Handle attachment format
    generate_search_results_attachment if options[:format] == :attachment && @results.any?

    mail(headers)
  end

  def error_response(sender_email, error_message)
    @error_message = error_message
    @instance_domain = LibreverseInstance.instance_domain

    mail(
      to: sender_email,
      subject: "Search error - #{LibreverseInstance.instance_domain}"
    )
  end

  private

  def format_results(results)
    # Convert results to a consistent format for email display
    results.map do |result|
      # Handle hash data (for testing), Experience objects, and UnifiedExperience objects
      if result.is_a?(Hash)
        # Already a hash, just ensure required keys exist
        {
          id: result[:id] || result["id"] || "unknown",
          title: result[:title] || result["title"] || "Untitled",
          author: result[:author] || result["author"],
          description: truncate_description(result[:description] || result["description"] || result[:content] || result["content"]),
          url: result[:url] || result["url"] || "#",
          created_at: result[:created_at] || result["created_at"] || Time.current,
          offline_available: result[:offline_available] || result["offline_available"] || false
        }
      elsif result.respond_to?(:experience)
        # This is likely a UnifiedExperience
        experience = result.experience
        {
          id: experience.id,
          title: experience.title,
          author: experience.author,
          description: truncate_description(experience.description),
          url: experience_url(experience),
          created_at: experience.created_at,
          offline_available: experience.offline_available
        }
      else
        # This is likely an Experience object directly
        {
          id: result.id,
          title: result.title,
          author: result.author,
          description: truncate_description(result.description),
          url: experience_url(result),
          created_at: result.created_at,
          offline_available: result.offline_available
        }
      end
    end
  end

  def truncate_description(description)
    return "" if description.blank?

    description.length > 200 ? "#{description[0...200]}..." : description
  end

  def experience_url(experience)
    # Generate URL for the experience
    protocol = LibreverseInstance.force_ssl? ? "https" : "http"
    "#{protocol}://#{LibreverseInstance.instance_domain}/experiences/#{experience.id}"
  end

  def generate_search_results_attachment
    # Create a JSON file with detailed search results
    json_data = {
      query: @query,
      instance: @instance_domain,
      federated: @federated,
      timestamp: Time.current.iso8601,
      total_results: @total_results,
      results: @results.map do |result|
        {
          id: result[:id],
          title: result[:title],
          author: result[:author],
          description: result[:description],
          url: result[:url],
          created_at: result[:created_at]&.iso8601
        }
      end
    }

    attachments["search_results_#{@query.parameterize}.json"] = {
      mime_type: "application/json",
      content: JSON.pretty_generate(json_data)
    }
  end
end
