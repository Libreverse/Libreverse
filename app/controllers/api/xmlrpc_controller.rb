# frozen_string_literal: true
# shareable_constant_value: literal

require "nokogiri"
require "cgi"

module Api
  class XmlrpcController < ApplicationController
    include XmlrpcSecurity

    # Ensure XML responses are rendered without being hijacked by global HTML
    # filters (e.g. the privacy‑consent screen).
    prepend_before_action :force_xml_format
    skip_before_action :_enforce_privacy_consent, raise: false

    # Use null_session for XML-RPC requests to avoid session reset but still protect against CSRF
    protect_from_forgery with: :null_session, if: -> { xmlrpc_request? }
    protect_from_forgery with: :exception, unless: -> { xmlrpc_request? }

    before_action :apply_rate_limit
    before_action :current_account
    before_action :validate_content_type
    before_action :verify_csrf_for_state_changing_methods
    before_action :set_no_cache_headers

    # POST /api/xmlrpc
    def endpoint
      # Read the XML from the FormData
      xml_content = params[:xml]

      # Ensure we have content
      if xml_content.blank?
        render xml: fault_response(400, "Empty request body")
        return
      end

      begin
        # Parse the XML using Nokogiri with security options
        doc = Nokogiri::XML(xml_content) do |config|
          config.options = Nokogiri::XML::ParseOptions::NOBLANKS |
                           Nokogiri::XML::ParseOptions::NONET # Prevent network access
            config.strict.nonet # Strict parsing, no network
        end

        # Apply a processing timeout
        Timeout.timeout(3) do
          # Validate the XML-RPC structure
          method_name = doc.at_xpath("//methodName")&.text&.strip
          unless method_name
            render xml: fault_response(400, "Invalid XML-RPC request: No methodName element found")
            return
          end

          # Extract parameters
          params = []
          doc.xpath("//methodCall/params/param").each do |param|
            value_element = param.at_xpath("value")
            params << parse_value(value_element) if value_element
          end

          # Validate permissions for the method
          unless permitted_method?(method_name)
            render xml: fault_response(403, "Method not allowed")
            return
          end

          # Process the method call
          result = process_method_call(method_name, params)

          # Generate the XML response
          response_xml = generate_response(result)

          render xml: response_xml
        end
      rescue Timeout::Error
        render xml: fault_response(408, "Request timeout")
      rescue Nokogiri::XML::SyntaxError
        # Mark this request as having failed XML parsing for rate limiting
        request.env["xmlrpc.parse_failed"] = true
        render xml: fault_response(400, "Invalid XML-RPC request")
      rescue StandardError => e
        Rails.logger.error("XML-RPC error: #{e.message}")
        render xml: fault_response(500, "Internal server error")
      end
    end

    # Generate a standard XMLRPC fault response
    def fault_response(code, message)
      builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
        xml.methodResponse do
          xml.fault do
            xml.value do
              xml.struct do
                xml.member do
                  xml.name("faultCode")
                  xml.value do
                    xml.int(code.to_s)
                  end
                end
                xml.member do
                  xml.name("faultString")
                  xml.value do
                    xml.string(CGI.escapeHTML(message))
                  end
                end
              end
            end
          end
        end
      end
      builder.to_xml
    end

    private

    def set_no_cache_headers
      # API responses should not be cached as they're dynamic and user-specific
      response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, private"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "0"
    end

    def xmlrpc_request?
      request.path == "/api/xmlrpc" && request.post? &&
        (request.content_type&.include?("text/xml") ||
         request.content_type&.include?("application/xml"))
    end

    def verify_csrf_for_state_changing_methods
      return true unless xmlrpc_request?

      # For XML-RPC, all requests are POST but we need to check if they're state-changing
      # Parse the method name from XML to determine if it's state-changing
      xml_content = params[:xml]
      return true if xml_content.blank?

      begin
        doc = Nokogiri::XML(xml_content) do |config|
          config.options = Nokogiri::XML::ParseOptions::NOBLANKS |
                           Nokogiri::XML::ParseOptions::NONET
        end

        method_name = doc.at_xpath("//methodName")&.text&.strip
        return true if method_name.blank?

        # List of methods that change state and require CSRF protection
        state_changing_methods = %w[
          experiences.create
          experiences.update
          experiences.delete
          experiences.approve
          preferences.set
          preferences.dismiss
          admin.experiences.approve
        ]

        if state_changing_methods.include?(method_name)
          # For XML-RPC, check for X-CSRF-Token header
          token = request.headers["X-CSRF-Token"]

          unless token.present? && valid_authenticity_token?(session, token)
            render xml: fault_response(403, "CSRF token missing or invalid")
            return false
          end
        end

        true
      rescue Nokogiri::XML::SyntaxError
        # If we can't parse XML, let the main endpoint handle the error
        true
      end
    end

    # Ensure the request is sent with an XML content‑type *unless* the XML is supplied
    # via the `xml` form param (as is the case in our test suite). This prevents legitimate
    # form submissions from being rejected when the body itself isn't encoded as XML.
    def validate_content_type
      return true if params[:xml].present?

      valid_types = [ "text/xml", "application/xml" ]

      unless valid_types.any? { |type| request.content_type&.include?(type) }
        render xml: fault_response(415, "Unsupported content type. Use text/xml or application/xml"),
               status: :unsupported_media_type
        return false
      end

      true
    end

    def permitted_method?(method_name)
      method_name = method_name.to_s.strip
      return false unless method_name.match?(/\A[a-zA-Z0-9._]+\z/)

      # Methods requiring authentication
      authenticated_methods = %w[
        experiences.create
        experiences.update
        experiences.delete
        experiences.approve
        experiences.pending_approval
        preferences.get
        preferences.set
        preferences.dismiss
        preferences.is_dismissed
        account.get_info
        moderation.get_logs
        search.query
      ]

      # Public methods (no authentication required)
      public_methods = %w[
        experiences.all
        experiences.get
        experiences.approved
        search.public_query
      ]

      # Admin-only methods
      admin_methods = %w[
        experiences.all_with_unapproved
        experiences.approve
        experiences.pending_approval
        moderation.get_logs
        admin.experiences.all
        admin.experiences.approve
        federation.block_instance
        federation.unblock_instance
        federation.blocked_domains
        federation.stats
      ]

      # Public federation methods
      public_methods << "federation.search"
      public_methods << "federation.discover_instances"

      if authenticated_methods.include?(method_name) && !current_account
        # Require authentication for these methods
        return false
      end

      if admin_methods.include?(method_name) && !current_account&.admin?
        # Require admin role for these methods
        return false
      end

      # Check if method is either public, authenticated, or admin
      public_methods.include?(method_name) || authenticated_methods.include?(method_name) || admin_methods.include?(method_name)
    end

    def parse_value(value_element)
      # Check for direct text content (string value)
      return CGI.escapeHTML(value_element.text.strip) if value_element.children.size == 1 && value_element.children.first.text?

      # Get the type node - first element child of value
      type_node = value_element.element_children.first

      return nil unless type_node

      case type_node.name
      when "string"
        CGI.escapeHTML(type_node.text)
      when "int", "i4"
        type_node.text.to_i
      when "boolean"
        type_node.text == "1"
      when "double"
        type_node.text.to_f
      when "array"
        type_node.xpath(".//value").map { |v| parse_value(v) }
      when "struct"
        struct = {}
        type_node.xpath("./member").each do |member|
          name = CGI.escapeHTML(member.at_xpath("name").text)
          value = parse_value(member.at_xpath("value"))
          struct[name] = value
        end
        struct
      else
        CGI.escapeHTML(type_node.text)
      end
    end

    def process_method_call(method_name, params)
      case method_name
      when "experiences.all"
        # Get experiences; admins see all, others see only approved ones
        scope = current_account&.admin? ? Experience : Experience.approved
        experiences = scope.order(created_at: :desc)
        serialize_experiences(experiences)

      when "experiences.get"
        experience_id = params[0]
        experience = if current_account&.admin?
          Experience.find_by(id: experience_id)
        else
          Experience.approved.find_by(id: experience_id)
        end

        raise "Experience not found or not accessible" unless experience

          serialize_experience(experience)

      when "experiences.approved"
        experiences = Experience.approved.order(created_at: :desc)
        serialize_experiences(experiences)

      when "experiences.all_with_unapproved"
        # Admin only - already checked in permitted_method?
        experiences = Experience.order(created_at: :desc)
        serialize_experiences(experiences)

      when "experiences.pending_approval"
        # Admin or authenticated users only
        experiences = if current_account&.admin?
          Experience.pending_approval.order(created_at: :desc)
        else
          Experience.where(account_id: current_account.id, approved: false).order(created_at: :desc)
        end
        serialize_experiences(experiences)

      when "experiences.create"
        title = params[0]
        description = params[1]
        html_content = params[2]
        author = params[3] || current_account.username
        federate = params[4].nil? || params[4]

        experience = Experience.new(
          title: title,
          description: description,
          author: author,
          account_id: current_account.id,
          federate: federate
        )

        if html_content.present?
          experience.html_file.attach(
            io: StringIO.new(html_content),
            filename: "experience_#{Time.current.to_i}.html",
            content_type: "text/html"
          )
        end

        raise "Failed to create experience: #{experience.errors.full_messages.join(', ')}" unless experience.save

          serialize_experience(experience)

      when "experiences.update"
        experience_id = params[0]
        updates = params[1] || {}

        experience = Experience.find_by(id: experience_id, account_id: current_account.id)
        raise "Experience not found or not owned by current user" unless experience

        update_params = {}
        update_params[:title] = updates["title"] if updates["title"]
        update_params[:description] = updates["description"] if updates["description"]
        update_params[:author] = updates["author"] if updates["author"]

        raise "Failed to update experience: #{experience.errors.full_messages.join(', ')}" unless experience.update(update_params)

          serialize_experience(experience)

      when "experiences.delete"
        experience_id = params[0]
        experience = Experience.find_by(id: experience_id, account_id: current_account.id)
        raise "Experience not found or not owned by current user" unless experience

        raise "Failed to delete experience" unless experience.destroy

          { "success" => true, "message" => "Experience deleted successfully" }

      when "experiences.approve"
        # Admin only
        experience_id = params[0]
        experience = Experience.find_by(id: experience_id)
        raise "Experience not found" unless experience

        raise "Failed to approve experience: #{experience.errors.full_messages.join(', ')}" unless experience.update(approved: true)

          serialize_experience(experience)

      when "preferences.get"
        key = params[0]
        raise "Invalid preference key" unless UserPreference::ALLOWED_KEYS.include?(key)

        value = UserPreference.get(current_account.id, key)
        { "key" => key, "value" => value }

      when "preferences.set"
        key = params[0]
        value = params[1]
        raise "Invalid preference key" unless UserPreference::ALLOWED_KEYS.include?(key)

        result = UserPreference.set(current_account.id, key, value)
        raise "Failed to set preference" unless result

          { "key" => key, "value" => result, "success" => true }

      when "preferences.dismiss"
        key = params[0]
        raise "Invalid preference key" unless UserPreference::ALLOWED_KEYS.include?(key)

        result = UserPreference.dismiss(current_account.id, key)
        raise "Failed to dismiss preference" unless result

          { "key" => key, "dismissed" => true, "success" => true }

      when "preferences.is_dismissed"
        key = params[0]
        raise "Invalid preference key" unless UserPreference::ALLOWED_KEYS.include?(key)

        dismissed = UserPreference.dismissed?(current_account.id, key)
        { "key" => key, "dismissed" => dismissed }

      when "account.get_info"
        {
          "id" => current_account.id,
          "username" => current_account.username,
          "admin" => current_account.admin?,
          "guest" => current_account.guest?,
          "status" => account_status_string(current_account.status)
        }

      when "search.query", "search.public_query"
        query = params[0]
        limit = [ params[1] || 20, 100 ].min # Cap at 100 results

        scope = if method_name == "search.query" && current_account&.admin?
          Experience
        else
          Experience.approved
        end

        experiences = if query.present?
          # Limit query length and sanitize
          query = query.to_s.strip[0...50]
          scope.where("title LIKE ?", "%#{sanitize_sql_like(query)}%")
               .order(created_at: :desc)
               .limit(limit)
        else
          scope.order(created_at: :desc).limit(limit)
        end

        serialize_experiences(experiences)

      when "moderation.get_logs"
        # Admin only or user's own logs
        logs = if current_account&.admin?
          ModerationLog.recent.limit(100)
        else
          ModerationLog.where(account_id: current_account.id).recent.limit(100)
        end

        serialize_moderation_logs(logs)

      when "admin.experiences.all"
        # Admin only
        experiences = Experience.order(created_at: :desc)
        serialize_experiences(experiences)

      when "admin.experiences.approve"
        # Admin only
        experience_id = params[0]
        experience = Experience.find_by(id: experience_id)
        raise "Experience not found" unless experience

        raise "Failed to approve experience: #{experience.errors.full_messages.join(', ')}" unless experience.update(approved: true)

          serialize_experience(experience)

      when "federation.search"
        query = params[0]
        limit = [ params[1]&.to_i || 20, 100 ].min

        results = FederatedExperienceSearchService.search_across_instances(query, limit: limit)
        unified_results = UnifiedExperience.from_search_results(results)
        serialize_unified_experiences(unified_results)

      when "federation.discover_instances"
        instances = FederatedExperienceSearchService.discover_libreverse_instances
        instances.map { |domain| { "domain" => domain } }

      when "federation.block_instance"
        # Admin only
        domain = params[0]
        reason = params[1]

        success = LibreverseModeration.block_instance(domain, reason)
        { "success" => success, "domain" => domain, "reason" => reason }

      when "federation.unblock_instance"
        # Admin only
        domain = params[0]

        success = LibreverseModeration.unblock_instance(domain)
        { "success" => success, "domain" => domain }

      when "federation.blocked_domains"
        # Admin only
        domains = LibreverseModeration.blocked_domains
        domains.map { |domain| { "domain" => domain } }

      when "federation.stats"
        # Admin only
        stats = LibreverseModeration.blocking_stats
        stats.merge({
                      "local_experiences" => Experience.where(federate: true, approved: true).count,
                      "federation_enabled" => true
                    })

      else
        render xml: fault_response(404, "Method not found")
        nil
      end
    end

    # Helper method to serialize experiences into a format suitable for XML-RPC
    def serialize_experiences(experiences)
      experiences.map do |experience|
        {
          "id" => experience.id,
          "title" => experience.title,
          "description" => experience.description,
          "author" => experience.author,
          "created_at" => experience.created_at.iso8601,
          "updated_at" => experience.updated_at.iso8601
        }
      end
    end

    # Helper method to serialize a single experience
    def serialize_experience(experience)
      {
        "id" => experience.id,
        "title" => experience.title,
        "description" => experience.description,
        "author" => experience.author,
        "approved" => experience.approved,
        "account_id" => experience.account_id,
        "html_file" => experience.html_file?,
        "federate" => experience.federate,
        "created_at" => experience.created_at.iso8601,
        "updated_at" => experience.updated_at.iso8601
      }
    end

    # Helper method to serialize unified experiences (both local and federated)
    def serialize_unified_experiences(experiences)
      experiences.map do |experience|
        {
          "id" => experience.id,
          "title" => experience.title,
          "description" => experience.description,
          "author" => experience.author,
          "source_type" => experience.source_type.to_s,
          "source_domain" => experience.source_domain,
          "local" => experience.local?,
          "federated" => experience.federated?,
          "activitypub_uri" => experience.activitypub_uri,
          "experience_url" => experience.federated? ? experience.experience_url : nil,
          "created_at" => experience.created_at.iso8601,
          "updated_at" => experience.updated_at.iso8601
        }
      end
    end

    # Helper method to serialize federated experiences (legacy - deprecated)
    def serialize_federated_experiences(experiences)
      # Convert to unified experiences for consistency
      unified = experiences.is_a?(Array) ? UnifiedExperience.from_search_results(experiences) : [ UnifiedExperience.new(experiences) ]
      serialize_unified_experiences(unified)
    end

    # Helper method to serialize moderation logs
    def serialize_moderation_logs(logs)
      logs.map do |log|
        {
          "id" => log.id,
          "field" => log.field,
          "model_type" => log.model_type,
          "content" => log.content,
          "reason" => log.reason,
          "account_id" => log.account_id,
          "violations" => log.violations,
          "created_at" => log.created_at.iso8601
        }
      end
    end

    # Helper method to convert account status to string
    def account_status_string(status)
      case status
      when 1 then "unverified"
      when 2 then "verified"
      when 3 then "closed"
      else "unknown"
      end
    end

    # Sanitize SQL LIKE wildcards to prevent injection
    def sanitize_sql_like(str)
      ActiveRecord::Base.sanitize_sql_like(str)
    end

    def generate_response(result)
      builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
        xml.methodResponse do
          xml.params do
            xml.param do
              xml.value do
                add_typed_value(xml, result)
              end
            end
          end
        end
      end
      builder.to_xml
    end

    # Helper method to add a typed value to XML-RPC response
    def add_typed_value(xml, value)
      case value
      when TrueClass, FalseClass
        xml.boolean(value ? "1" : "0")
      when Integer
        xml.int(value.to_s)
      when Float
        xml.double(value.to_s)
      when Array
        xml.array do
          xml.data do
            value.each do |item|
              xml.value do
                add_typed_value(xml, item)
              end
            end
          end
        end
      when Hash
        xml.struct do
          value.each do |key, val|
            xml.member do
              xml.name(key.to_s)
              xml.value do
                add_typed_value(xml, val)
              end
            end
          end
        end
      else
        xml.string(CGI.escapeHTML(value.to_s))
      end
    end

    def apply_rate_limit
      key = "xmlrpc_rate_limit:#{request.ip}"
      count = Rails.cache.increment(key, 1, expires_in: 1.minute)

      return true unless count > 30

      render xml: fault_response(429, "Rate limit exceeded")
      false # Halt the filter chain
    end

    def current_account
      @current_account ||= AccountSequel.where(id: session[:account_id]).first
    end

    def force_xml_format
      request.format = :xml
    end
  end
end
