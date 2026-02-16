# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

require "re2"

module Admin
  # Controller for managing federation features within the Admin namespace
  class FederationController < BaseController
    before_action :set_blocked_domain, only: [ :unblock_domain ]

    # GET /admin/federation
    def index
      @stats = LibreverseModeration.blocking_stats
      @blocked_domains = LibreverseModeration.blocked_domains
      @recent_federated_actors = Federails::Actor.where(local: false).order(created_at: :desc).limit(10)
      @federation_enabled = true
      @federated_experiences_count = Experience.where(federate: true, approved: true).count
    end

    # GET /admin/federation/federated_experiences
    def federated_experiences
      # This would show experiences from other instances
      # For now, we'll show local federated experiences
      @experiences = Experience.federating.includes(:account).order(created_at: :desc).limit(50)
    end

    def unblock_domain
      return unless @domain

      LibreverseModeration.unblock_domain(@domain)
      redirect_to admin_federation_path, notice: "Domain #{@domain} unblocked"
    end

    private

    def set_blocked_domain
      # Normalize domain: strip whitespace and convert to lowercase
      @domain = params[:domain]&.strip&.downcase

      # Validate domain format if present
      return if @domain.blank?

        domain_regex = RE2::Regexp.new('\A(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\z', case_insensitive: true)

        return if domain_regex.match?(@domain)

          redirect_to admin_federation_path, alert: "Invalid domain format"
          nil
    end
  end
end
