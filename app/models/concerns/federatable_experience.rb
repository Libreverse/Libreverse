# frozen_string_literal: true

# Concern to add ActivityPub federation capabilities to Experience model
module FederatableExperience
  extend ActiveSupport::Concern

  included do
    # Don't use Federails::DataEntity for now - we'll handle federation manually
    # include Federails::DataEntity
    # acts_as_federails_data handles: 'Note'

    after_commit :federate_experience_activity, on: %i[create update], if: :should_federate?
    after_destroy :federate_experience_deletion, if: :should_federate?
  end

  # Manual implementation of federails_uri for experiences
  def federails_uri
    return nil unless account&.federails_actor

    "#{account.federails_actor.federated_url}/experiences/#{id}"
  end

  def federails_content
    # Security: Only send safe metadata for link-exclusive federation
    # Never include vectors, full content, or manipulable data
    {
      "@context" => [
        "https://www.w3.org/ns/activitystreams",
        "https://libreverse.org/ns"
      ],
      type: "Note",
      id: federails_uri,
      url: federails_uri, # Link back to original instance
      attributedTo: account&.federails_actor&.federated_url,
      name: title,
      content: description&.truncate(
        InstanceSetting.get_with_fallback("federation_description_limit", nil, "300").to_i
      ), # Configurable limit for federation security
      published: created_at.iso8601,
      updated: updated_at.iso8601,
      # Custom Libreverse fields - only safe metadata
      "libreverse:experienceType" => "interactive_html",
      "libreverse:author" => author,
      "libreverse:moderationStatus" => approved? ? "approved" : "pending",
      "libreverse:instanceDomain" => Rails.application.config.x.instance_domain,
      "libreverse:creatorAccount" => account&.username
      # Security: Never include vectors, full HTML content, interaction capabilities,
      # tags, or other data that could be manipulated to attack search systems
    }
  end

  def should_federate?
    # Only federate approved experiences to prevent spam/malicious content
    # User must explicitly opt-in to federation
    federate? && approved?
  end

  # Security: Remove methods that could expose vectors or manipulable data
  # The following methods are intentionally removed for security:
  # - html_file_activitypub_attachment (exposes full content)
  # - html_file_url (exposes downloadable content)
  # - interaction_capabilities (could be manipulated)
  # - extract_tags_from_description (could be manipulated)

  private

  def federate_experience_activity
    return unless should_federate?

    FederateExperienceJob.perform_later(self, activity_type)
  end

  def federate_experience_deletion
    FederateExperienceDeletionJob.perform_later(federails_uri) if federails_uri
  end

  def activity_type
    saved_change_to_id? ? "Create" : "Update"
  end
end
