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

    def should_federate_to?(_domain)
      # For now, allow federation to all domains
      true
    end

    def blocked_domains
      # Return empty array for now
      []
    end

    def blocking_stats
      {
        blocked_domains_count: 0,
        blocked_experiences_count: Experience.where(federated_blocked: true).count,
        total_federated_actors: 0
      }
    end
  end
end
