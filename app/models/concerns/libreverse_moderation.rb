# frozen_string_literal: true

# Concern for handling Libreverse-specific moderation features
module LibreverseModeration
  extend ActiveSupport::Concern

  class_methods do
    def block_instance(domain, reason = nil)
      # For now, just log the blocking - can implement full federation blocking later
      Rails.logger.info "Would block federation with domain: #{domain} (reason: #{reason})"
      true
    end

    def unblock_instance(domain)
      Rails.logger.info "Would unblock federation with domain: #{domain}"
      true
    end

    def should_federate_to?(domain)
      # Check if the domain is in the blocked domains list
      # Return false if blocked, true if allowed
      return false if domain.blank?

      !blocked_domains.include?(domain.to_s.downcase.strip)
    end

    def blocked_domains
      # Return empty array for now
      []
    end

    def blocking_stats
      {
        blocked_domains_count: BlockedDomain.count,
        blocked_experiences_count: Experience.where(federated_blocked: true).count,
        total_federated_actors: Federails::Actor.count
      }
    end
  end
end
