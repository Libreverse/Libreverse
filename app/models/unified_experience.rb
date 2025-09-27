# Unified interface for both local and federated experiences
# This allows us to treat them the same in search results and UI
class UnifiedExperience
  attr_reader :id, :title, :description, :author, :created_at, :updated_at,
              :source_type, :source_domain, :experience_url, :activitypub_uri,
              :metaverse_platform

  def initialize(source)
    case source
    when Experience
      # Local experience
      @id = source.id
      @title = source.title
      @description = source.description
      @author = source.author
      @created_at = source.created_at
      @updated_at = source.updated_at
      @source_type = :local
      @source_domain = safe_instance_domain
      @experience_url = nil # Will use regular display path
      @activitypub_uri = nil
      @metaverse_platform = nil
      @source_object = source
    when FederatedAnnouncement
      # Federated experience announcement
      @id = "fed_#{source.id}"
      @title = source.title
      @description = "Experience from #{source.source_domain}"
      @author = "Remote User"
      @created_at = source.announced_at
      @updated_at = source.announced_at
      @source_type = :federated
      @source_domain = source.source_domain
      @experience_url = source.experience_url
      @activitypub_uri = source.activitypub_uri
      @metaverse_platform = nil
      @source_object = source
    when IndexedContent
      # Metaverse content
      @id = "metaverse_#{source.id}"
      @title = source.title
      @description = source.description
      @author = source.author
      @created_at = source.created_at
      @updated_at = source.updated_at
      @source_type = :metaverse
      @source_domain = source.source_platform
      @experience_url = generate_metaverse_url(source)
      @activitypub_uri = nil
      @metaverse_platform = source.source_platform
      @source_object = source
    else
      raise ArgumentError, "Unknown source type: #{source.class}"
    end
  end

  # Safe method to get instance domain that works during tests and initialization
  def safe_instance_domain
    # Try to get from application if available
    if defined?(LibreverseInstance::Application) &&
       LibreverseInstance::Application.respond_to?(:instance_domain)
      begin
        LibreverseInstance::Application.instance_domain
      rescue StandardError
        fallback_instance_domain
      end
    else
      fallback_instance_domain
    end
  end

  private

  def fallback_instance_domain
    # Use environment variable or localhost as fallback
    ENV["INSTANCE_DOMAIN"] || "localhost"
  end

  def generate_metaverse_url(indexed_content)
    case indexed_content.source_platform
    when "decentraland"
      generate_decentraland_url(indexed_content)
    end
  end

  def generate_decentraland_url(indexed_content)
    return nil if indexed_content.coordinates.blank?

    coords = indexed_content.coordinates
    if coords["x"].present? && coords["y"].present?
      "https://play.decentraland.org/?position=#{coords['x']},#{coords['y']}"
    else
      "https://play.decentraland.org/"
    end
  end

  public

  # For compatibility with existing views and paths
  def to_param
    @source_type == :local ? @source_object.to_param : @id
  end

  def local?
    @source_type == :local
  end

  def federated?
    @source_type == :federated
  end

  def metaverse?
    @source_type == :metaverse
  end

  def coordinates
    return nil unless metaverse? && @source_object.coordinates.present?

    @source_object.coordinates
  end

  # For use in routes/path helpers
  def display_path
    if local?
      Rails.application.routes.url_helpers.display_experience_path(@source_object)
    elsif metaverse?
      @experience_url # Direct link to metaverse experience
    else
      @experience_url # Direct link to federated experience
    end
  end

  # Method delegation to maintain compatibility
  def announced_at
    federated? ? @created_at : nil
  end

  def approved?
    local? ? @source_object.approved? : true # Federated experiences are implicitly approved
  end

  def account
    local? ? @source_object.account : nil
  end

  def account_id
    local? ? @source_object.account_id : nil
  end

  def html_file
    local? ? @source_object.html_file : nil
  end

  def experience_vector
    local? ? @source_object.experience_vector : nil
  end

  def needs_vectorization?
    local? ? @source_object.needs_vectorization? : false
  end

  def federated_experience_link
    self # Return self since this is already the unified interface
  end

  class << self
    # Create unified experiences from search results
    def from_search_results(results)
      results.map do |result|
        if result.is_a?(Experience)
          new(result)
        elsif result.respond_to?(:activitypub_uri) && result.activitypub_uri
          # This is a federated announcement, find the source
          announcement = FederatedAnnouncement.find_by(activitypub_uri: result.activitypub_uri)
          announcement ? new(announcement) : nil
        else
          # Try to wrap directly
          new(result)
        end
      end.compact
    end
  end
end
