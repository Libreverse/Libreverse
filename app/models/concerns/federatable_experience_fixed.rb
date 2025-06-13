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
    {
      "@context" => [
        "https://www.w3.org/ns/activitystreams",
        "https://libreverse.org/ns"
      ],
      type: "Note",
      id: federails_uri,
      attributedTo: account&.federails_actor&.federated_url,
      name: title,
      content: description,
      mediaType: "text/html",
      attachment: html_file_attachment,
      published: created_at.iso8601,
      updated: updated_at.iso8601,
      # Custom Libreverse fields for metaverse experiences
      "libreverse:experienceType" => "interactive_html",
      "libreverse:author" => author,
      "libreverse:approved" => approved,
      "libreverse:htmlContent" => html_file_url,
      "libreverse:moderationStatus" => moderation_status,
      "libreverse:interactionCapabilities" => interaction_capabilities,
      "libreverse:tags" => extract_tags_from_description,
      "libreverse:instanceDomain" => Rails.application.config.x.instance_domain,
      "libreverse:creatorAccount" => account&.username
    }
  end

  private

  def html_file_attachment
    return nil unless html_file.attached?

    {
      type: "Document",
      mediaType: "text/html",
      name: "#{title} - Interactive Experience",
      url: html_file_url
    }
  end

  def html_file_url
    return nil unless html_file.attached?

    Rails.application.routes.url_helpers.rails_blob_url(
      html_file,
      host: Rails.application.config.x.instance_domain
    )
  end

  def interaction_capabilities
    %w[
      navigate
      interact
      immersive_view
    ]
  end

  def moderation_status
    return "pending" unless approved?

    "approved"
  end

  def extract_tags_from_description
    # Extract hashtags or keywords from description
    description&.scan(/#\w+/) || []
  end

  def federate_experience_activity
    return unless should_federate?

    FederateExperienceJob.perform_later(self, activity_type)
  end

  def federate_experience_deletion
    FederateExperienceDeletionJob.perform_later(federails_uri) if federails_uri
  end

  def should_federate?
    # Only federate experiences that:
    # 1. Have federation enabled
    # 2. Are approved
    # 3. Belong to verified accounts
    # 4. Have a federails actor
    federate && approved? && account&.verified? && !Rails.env.test? && account.federails_actor
  end

  def activity_type
    saved_change_to_id? ? "Create" : "Update"
  end
end
