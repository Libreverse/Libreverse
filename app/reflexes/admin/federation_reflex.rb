# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

module Admin
  class FederationReflex < ApplicationReflex
    def block_domain
      authorize_admin!
      domain = element.dataset[:domain] || params[:domain]
      reason = element.dataset[:reason] || params[:reason]

      # Validation logic...
      # For simplicity in Reflex, we might rely on the service or simple checks
      if LibreverseModeration.block_instance(domain, reason)
        morph :nothing
        cable_ready.console_log(message: "Blocked #{domain}")
        # Refresh the list
        morph "#blocked-domains-list", render(partial: "admin/federation/blocked_domains_list")
      else
        cable_ready.console_log(message: "Failed to block #{domain}")
      end
    end

    def unblock_domain
      authorize_admin!
      domain = element.dataset[:domain]

      return unless LibreverseModeration.unblock_instance(domain)

        morph :nothing
        cable_ready.console_log(message: "Unblocked #{domain}")
        # Refresh the list
        morph "#blocked-domains-list", render(partial: "admin/federation/blocked_domains_list")
    end

    def generate_actors
      authorize_admin!
      count = GenerateMissingActorsJob.perform_now
      cable_ready.console_log(message: "Generated #{count} actors")
      morph :nothing
    end

    private

    def authorize_admin!
      raise "Unauthorized" unless current_account&.admin?
    end
  end
end
