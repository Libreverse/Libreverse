# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

# Service for handling URL templates using Addressable::Template
# Provides efficient URL generation and extraction with RFC 6570 compliance
class UrlTemplateService
  require "addressable/template"

  # Common URL templates used across the application
  TEMPLATES = {
    # API endpoints
    api_search: "https://{domain}/api/search{?query,limit,offset}",
    api_user: "https://{domain}/api/users/{user_id}",

    # Federation endpoints
    federation_webfinger: "https://{domain}/.well-known/webfinger{?resource,rel}",
    federation_oidc_config: "https://{domain}/.well-known/openid-configuration",
    federation_register: "https://{domain}/register{?redirect_uri,client_name,scope}",

    # Sitemap templates
    sitemap: "https://{domain}/sitemap.xml",
    sitemap_index: "https://{domain}/sitemap-index.xml",

    # CDN/Asset templates
    cdn_asset: "https://cdn.{domain}/assets/{path*}",

    # OAuth templates
    oauth_authorize: "https://{domain}/oauth/authorize{?response_type,client_id,redirect_uri,scope,state}",
    oauth_token: "https://{domain}/oauth/token"
  }.freeze

  class << self
    # Generate URL from template with parameters
    # @param template_key [Symbol] Key from TEMPLATES hash
    # @param params [Hash] Parameters to substitute in template
    # @return [Addressable::URI] Generated URI
    def generate_url(template_key, params = {})
      template = TEMPLATES[template_key]
      raise ArgumentError, "Unknown template: #{template_key}" unless template

      addressable_template = Addressable::Template.new(template)
      addressable_template.expand(params)
    end

    # Extract parameters from URL using template
    # @param template_key [Symbol] Key from TEMPLATES hash
    # @param url [String] URL to extract from
    # @return [Hash] Extracted parameters
    def extract_params(template_key, url)
      template = TEMPLATES[template_key]
      raise ArgumentError, "Unknown template: #{template_key}" unless template

      addressable_template = Addressable::Template.new(template)
      addressable_template.extract(url)
    end

    # Partially expand template with some parameters
    # @param template_key [Symbol] Key from TEMPLATES hash
    # @param params [Hash] Parameters to substitute
    # @return [Addressable::Template] Partially expanded template
    def partial_expand(template_key, params = {})
      template = TEMPLATES[template_key]
      raise ArgumentError, "Unknown template: #{template_key}" unless template

      addressable_template = Addressable::Template.new(template)
      addressable_template.partial_expand(params)
    end

    # Parse and normalize a URI with better error handling
    # @param url [String] URL to parse
    # @return [Addressable::URI, nil] Parsed URI or nil if invalid
    def parse_uri(url)
      return nil if url.blank?

      begin
        # Use heuristic_parse for better handling of incomplete URLs
        Addressable::URI.heuristic_parse(url)
      rescue Addressable::URI::InvalidURIError => e
        Rails.logger.warn "Invalid URI: #{url} - #{e.message}"
        nil
      end
    end

    # Validate URL with specific requirements
    # @param url [String] URL to validate
    # @param options [Hash] Validation options
    # @return [Boolean] True if valid
    def valid_url?(url, options = {})
      uri = parse_uri(url)
      return false unless uri

      # Check scheme
      if (allowed_schemes = options[:schemes]) && !allowed_schemes.include?(uri.scheme)
        return false
      end

      # Check host
      return false if uri.host.blank?

      # Check port
      if (allowed_ports = options[:ports])
        port = uri.port || (uri.scheme == "https" ? 443 : 80)
        return false unless allowed_ports.include?(port)
      end

      true
    end

    # Normalize URL for comparison/storage
    # @param url [String] URL to normalize
    # @return [String, nil] Normalized URL or nil if invalid
    def normalize_url(url)
      uri = parse_uri(url)
      return nil unless uri

      uri.normalize.to_s
    end

    # Extract domain from URL with better error handling
    # @param url [String] URL to extract domain from
    # @return [String, nil] Domain or nil if invalid
    def extract_domain(url)
      uri = parse_uri(url)
      return nil unless uri

      uri.host
    end

    # Check if URL belongs to same domain
    # @param url1 [String] First URL
    # @param url2 [String] Second URL
    # @return [Boolean] True if same domain
    def same_domain?(url1, url2)
      domain1 = extract_domain(url1)
      domain2 = extract_domain(url2)

      return false if domain1.blank? || domain2.blank?

      domain1.downcase == domain2.downcase
    end

    # Generate webfinger URL for a domain
    # @param domain [String] Domain
    # @param resource [String] Resource (e.g., "acct:user@domain.com")
    # @return [String] Webfinger URL
    def webfinger_url(domain, resource)
      generate_url(:federation_webfinger, { domain: domain, resource: resource }).to_s
    end

    # Generate OIDC config URL for a domain
    # @param domain [String] Domain
    # @return [String] OIDC config URL
    def oidc_config_url(domain)
      generate_url(:federation_oidc_config, { domain: domain }).to_s
    end
  end
end
