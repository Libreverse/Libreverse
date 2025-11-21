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

    # POST /admin/federation/block_domain
    def block_domain
      # Normalize domain: strip whitespace and convert to lowercase
      domain = params[:domain]&.strip&.downcase
      reason = params[:reason]&.strip

      if domain.blank?
        redirect_to admin_federation_path, alert: "Domain cannot be blank"
        return
      end

      # Validate domain format using RE2 regex
      # Matches valid domain names including subdomains, internationalized domains, and standard TLDs
      domain_regex = RE2::Regexp.new('\A(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\z', case_insensitive: true)

      unless domain_regex.match?(domain)
        redirect_to admin_federation_path, alert: "Invalid domain format"
        return
      end

      if LibreverseModeration.block_instance(domain, reason)
        redirect_to admin_federation_path, notice: "Successfully blocked domain: #{domain}"
      else
        redirect_to admin_federation_path, alert: "Failed to block domain: #{domain}"
      end
    end

    # DELETE /admin/federation/unblock_domain/:domain
    def unblock_domain
      # Normalize domain: strip whitespace and convert to lowercase
      domain = params[:domain]&.strip&.downcase

      if domain.blank?
        redirect_to admin_federation_path, alert: "Domain cannot be blank"
        return
      end

      # Validate domain format using RE2 regex
      domain_regex = RE2::Regexp.new('\A(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\z', case_insensitive: true)

      unless domain_regex.match?(domain)
        redirect_to admin_federation_path, alert: "Invalid domain format"
        return
      end

      if LibreverseModeration.unblock_instance(domain)
        redirect_to admin_federation_path, notice: "Successfully unblocked domain: #{domain}"
      else
        redirect_to admin_federation_path, alert: "Failed to unblock domain: #{domain}"
      end
    end

    # POST /admin/federation/generate_actors
    def generate_actors
      count = GenerateMissingActorsJob.perform_now
      redirect_to admin_federation_path, notice: "Generated #{count} new federation actors"
    rescue StandardError => e
      redirect_to admin_federation_path, alert: "Failed to generate actors: #{e.message}"
    end

    # GET /admin/federation/federated_experiences
    def federated_experiences
      # This would show experiences from other instances
      # For now, we'll show local federated experiences
      @experiences = Experience.federating.includes(:account).order(created_at: :desc).limit(50)
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
