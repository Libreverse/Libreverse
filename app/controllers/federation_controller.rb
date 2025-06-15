# frozen_string_literal: true

# Controller for ActivityPub federation endpoints and discovery
class FederationController < ApplicationController
  before_action :set_activitypub_headers

  def libreverse_discovery
    render json: {
      software: "libreverse",
      version: "1.0.0",
      capabilities: %w[
        interactive_html_experiences
        experience_federation
        content_moderation
        search_federation
      ],
      endpoints: {
        experiences: federation_experiences_collection_url,
        search: federation_search_url
      },
      "@context" => "https://libreverse.org/ns"
    }
  end

  def experiences_collection
    # Only share metadata and links, not full content or vectors
    experiences = Experience.approved.includes(:account).limit(params[:limit]&.to_i || 20)

    render json: {
      "@context" => [
        "https://www.w3.org/ns/activitystreams",
        "https://libreverse.org/ns"
      ],
      type: "Collection",
      id: request.url,
      totalItems: Experience.approved.count,
      items: experiences.map { |exp| safe_experience_metadata(exp) }
    }
  end

  def search
    query = params[:q]
    type_filter = params[:type]
    limit = [ params[:limit]&.to_i || 20, 100 ].min
    links_only = params[:links_only] == "true"

    results = if type_filter == "experience"
      search_experiences(query, limit)
    else
      []
    end

    # If links_only is requested, only return safe metadata
    items = if links_only
      results.map { |exp| safe_experience_metadata(exp) }
    else
      results.map(&:federails_content)
    end

    render json: {
      "@context" => [
        "https://www.w3.org/ns/activitystreams",
        "https://libreverse.org/ns"
      ],
      type: "Collection",
      totalItems: results.size,
      items: items
    }
  end

  # Endpoint for receiving announcements from other Libreverse instances
  def announce
    announcement_data = JSON.parse(request.body.read)

    # Validate the announcement is from a known Libreverse instance
    source_domain = extract_domain_from_actor(announcement_data["actor"])
    return head :forbidden unless libreverse_instance?(source_domain)

    # Store the announcement for discovery (not the actual content)
    store_federated_announcement(announcement_data, source_domain)

    head :ok
  rescue JSON::ParserError
    head :bad_request
  rescue StandardError => e
    Rails.logger.error "Failed to process announcement: #{e.message}"
    head :internal_server_error
  end

  private

  def set_activitypub_headers
    response.headers["Content-Type"] = "application/activity+json; charset=utf-8"
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Accept, Content-Type, Authorization"
  end

  def search_experiences(query, limit)
    return [] if query.blank?

    # Use existing search service but filter for approved experiences
    ExperienceSearchService.search(
      query,
      scope: Experience.approved.includes(:account),
      limit: limit,
      use_vector_search: true
    )
  end

  def safe_experience_metadata(experience)
    # Only return safe metadata for link-exclusive federation
    {
      "@context" => [
        "https://www.w3.org/ns/activitystreams",
        "https://libreverse.org/ns"
      ],
      type: "Note",
      id: experience.federails_uri,
      url: experience.federails_uri, # Link back to original instance
      name: experience.title,
      content: experience.description&.truncate(300), # Limit description length
      attributedTo: experience.account&.federails_actor&.federated_url,
      published: experience.created_at.iso8601,
      "libreverse:author" => experience.author,
      "libreverse:moderationStatus" => experience.approved? ? "approved" : "pending",
      "libreverse:instanceDomain" => current_instance_domain,
      "libreverse:experienceType" => "interactive_html"
      # Security: Never include vectors, detailed content, or manipulable metadata
    }
  end

  def extract_domain_from_actor(actor_url)
    URI(actor_url).host
  rescue StandardError
    nil
  end

  def libreverse_instance?(domain)
    return false unless domain

    url = if URI::DEFAULT_PARSER.make_regexp(%w[http https]).match?(domain)
      domain
    else
      "https://#{domain}/.well-known/libreverse"
    end

    response = HTTParty.get(url, timeout: 3)

    if response.code == 200
      data = JSON.parse(response.body)
      data["software"] == "libreverse"
    else
      false
    end
  rescue StandardError
    false
  end

  def store_federated_announcement(announcement_data, source_domain)
    # Store only announcement metadata, not actual content
    object = announcement_data["object"]

    # Create a federated announcement record for discovery
    FederatedAnnouncement.create!(
      activitypub_uri: object["id"],
      title: object["name"]&.truncate(255),
      source_domain: source_domain,
      announced_at: Time.current,
      experience_url: object["url"] || object["id"]
    )
  rescue StandardError => e
    Rails.logger.warn "Failed to store federated announcement: #{e.message}"
  end
end
