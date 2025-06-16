# frozen_string_literal: true

# Module for handling Libreverse-specific moderation features
module LibreverseModeration
  module_function

  def block_instance(domain, reason = nil)
      # Create or update blocked domain record

      blocked_domain = BlockedDomain.find_or_initialize_by(domain: domain.to_s.downcase.strip)
      blocked_domain.reason = reason if reason.present?
      blocked_domain.blocked_at = Time.current
      blocked_domain.blocked_by = "system" # Could be enhanced to track which admin blocked it

      if blocked_domain.save
        Rails.logger.info "Blocked federation with domain: #{domain} (reason: #{reason})"
        true
      else
        Rails.logger.error "Failed to block domain #{domain}: #{blocked_domain.errors.full_messages.join(', ')}"
        false
      end
  rescue StandardError => e
      Rails.logger.error "Error blocking domain #{domain}: #{e.message}"
      false
  end

  def unblock_instance(domain)
      normalized_domain = domain.to_s.downcase.strip
      blocked_domain = BlockedDomain.find_by(domain: normalized_domain)

      if blocked_domain&.destroy && blocked_domain.destroyed?
        Rails.logger.info "Unblocked federation with domain: #{domain}"
        true
      else
        Rails.logger.warn "Attempted to unblock domain that wasn't blocked: #{domain}"
        false
      end
  rescue StandardError => e
      Rails.logger.error "Error unblocking domain #{domain}: #{e.message}"
      false
  end

  def should_federate_to?(domain)
    # Check if the domain is in the blocked domains list
    # Return false if blocked, true if allowed
    return false if domain.blank?

    !BlockedDomain.blocked?(domain.to_s.downcase.strip)
  end

  def blocked_domains
    BlockedDomain.pluck(:domain)
  end

  def blocking_stats
    {
      blocked_domains_count: BlockedDomain.count,
      blocked_experiences_count: Experience.where(federated_blocked: true).count,
      total_federated_actors: Federails::Actor.where(local: false).count
    }
  end
end
