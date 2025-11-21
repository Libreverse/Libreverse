# frozen_string_literal: true
# shareable_constant_value: literal

# Job to handle federating experience activities via ActivityPub
class FederateExperienceJob < ApplicationJob
  queue_as :federation

  def perform(experience, activity_type)
    # Ensure the experience and account still exist
    return unless experience&.account

    actor = experience.account.federails_actor
    return unless actor&.local?

    activity = build_activity(experience, activity_type, actor)

    # Send activity manually using HTTP requests instead of Federails::DeliveryService
    # to avoid the actor configuration issue
    deliver_activity_manually(actor, activity)

    Rails.logger.info "Federated #{activity_type} activity for experience #{experience.id}"
  rescue StandardError => e
    Rails.logger.error "Failed to federate experience #{experience.id}: #{e.message}"
    # Don't re-raise to avoid job failures
  end

  private

  def build_activity(experience, activity_type, actor)
    {
      "@context" => [
        "https://www.w3.org/ns/activitystreams",
        "https://libreverse.org/ns"
      ],
      id: "#{actor.federated_url}/activities/#{SecureRandom.uuid}",
      type: activity_type,
      actor: actor.federated_url,
      "object" => experience.federails_content,
      published: Time.current.iso8601,
      to: determine_recipients(experience, actor)
    }
  end

  def determine_recipients(experience, _actor)
    recipients = []

    # Add public collection for approved experiences
    recipients << "https://www.w3.org/ns/activitystreams#Public" if experience.approved?

    # Add Libreverse-specific collection for cross-instance discovery
    recipients << "https://libreverse.org/ns#LibreverseNetwork"

    recipients
  end

  def deliver_activity_manually(actor, activity)
    # Federation is link-exclusive only - we announce content but don't sync data
    # Other instances can discover and link to our content, but data stays local

    # Get known Libreverse instances for content announcement
    libreverse_instances = discover_libreverse_instances

    # Announce to Libreverse network for discovery (not data sync)
    libreverse_instances.each do |domain|
      announce_to_instance(domain, activity, actor)
    end

    Rails.logger.info "Announced activity to #{libreverse_instances.count} Libreverse instances"
  end

  def discover_libreverse_instances
    # Get known Libreverse instances from discovery endpoint calls
    # Could be populated from a registry, manual admin additions, or peer discovery
    # For now, return domains that have successfully announced to us
    Federails::Actor.where(local: false)
                    .where.not(server: nil)
                    .distinct
                    .pluck(:server)
                    .select { |domain| FederationHelper.libreverse_instance?(domain) }
  end

  def announce_to_instance(domain, activity, actor)
    # Send announcement to instance's discovery endpoint
    return unless /\A[a-z0-9\-.]+\z/i.match?(domain) # allow hostname only

    url = "https://#{domain}/api/activitypub/announce"

    # Only send link and metadata, not full content
    announcement = {
      "@context" => activity["@context"],
      "type" => "Announce",
      "actor" => actor.federated_url,
      "object" => {
        "id" => activity["object"]["id"],
        "type" => activity["object"]["type"],
        "name" => activity["object"]["name"],
        "url" => activity["object"]["id"], # Link back to original
        "attributedTo" => activity["object"]["attributedTo"],
        "published" => activity["object"]["published"],
        "libreverse:instanceDomain" => LibreverseInstance::Application.instance_domain
      },
      "published" => Time.current.iso8601
    }

    response = HTTParty.post(url,
                             body: announcement.to_json,
                             headers: {
                               "Content-Type" => "application/activity+json",
                               "User-Agent" => "Libreverse/1.0 (#{LibreverseInstance::Application.instance_domain})"
                             },
                             timeout: 5)

    if response.code >= 200 && response.code < 300
      Rails.logger.info "Successfully announced to #{domain}"
    else
      Rails.logger.warn "Failed to announce to #{domain}: #{response.code}"
    end
  rescue StandardError => e
    Rails.logger.warn "Error announcing to #{domain}: #{e.message}"
  end

  def libreverse_instance?(domain)
    FederationHelper.libreverse_instance?(domain)
  end
end
