# frozen_string_literal: true

require "stringio"

module Api
  class JsonController < ApplicationController
    include XmlrpcSecurity

    # Don't use any layout for JSON responses
    layout false

    # Ensure JSON responses are rendered without being hijacked by global HTML
    # filters (e.g. the privacy‑consent screen).
    prepend_before_action :force_json_format
    skip_before_action :_enforce_privacy_consent, raise: false

    # Use null_session for JSON requests to avoid session reset but still protect against CSRF
    protect_from_forgery with: :null_session, if: -> { json_request? }
    protect_from_forgery with: :exception, unless: -> { json_request? }

    before_action :apply_rate_limit
    before_action :current_account
    before_action :validate_content_type
    before_action :verify_csrf_for_state_changing_methods
    before_action :set_no_cache_headers

    # GET/POST /api/json/:method
    def endpoint
      method_name = params[:method]

      # Validate method name format (no consecutive dots, must start/end with alphanumeric, allow underscores)
      unless method_name.present? && method_name.match?(/\A[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)*\z/)
        @error_message = "Invalid method name"
        render "api/json/error", status: :bad_request
        return
      end

      # Validate permissions for the method
      unless permitted_method?(method_name)
        @error_message = "Method not allowed"
        render "api/json/error", status: :forbidden
        return
      end

      # Extract parameters from request
      method_params = extract_params

      begin
        # Apply a processing timeout
        ActiveSupport::Notifications.instrument("json_api.process") do
          process_method_call(method_name, method_params)
        end
        # Rack / Puma request_timeout middleware or nginx proxy_timeout
        # should already enforce an upper bound on total request time.
      rescue Timeout::Error
        @error_message = "Request timeout"
        render "api/json/error", status: :request_timeout
      rescue StandardError => e
        Rails.logger.error("JSON API error: #{e.message}")
        @error_message = "Internal server error"
        render "api/json/error", status: :internal_server_error
      end
    end

    private

    def set_no_cache_headers
      # API responses should not be cached as they're dynamic and user-specific
      response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, private"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "0"
    end

    def json_request?
      request.path.start_with?("/api/json") &&
        (request.content_type&.include?("application/json") || params[:method].present?)
    end

    def verify_csrf_for_state_changing_methods
      return true unless json_request?
      return true if request.get? || request.head? || request.options?

      # For state-changing methods (POST, PUT, PATCH, DELETE), require CSRF token
      method_name = params[:method]
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
        # Check for X-CSRF-Token header or form authenticity token
        token = request.headers["X-CSRF-Token"] || params[:authenticity_token]

        unless token.present? && valid_authenticity_token?(session, token)
          @error_message = "CSRF token missing or invalid"
          render "api/json/error", status: :forbidden
          return false
        end
      end

      true
    end

    def validate_content_type
      return true if params[:method].present? # Allow URL parameter method calls

      valid_types = [ "application/json", "text/json" ]

      unless valid_types.any? { |type| request.content_type&.include?(type) }
        @error_message = "Unsupported content type. Use application/json"
        render "api/json/error", status: :unsupported_media_type
        return false
      end

      true
    end

    def extract_params
      # Handle different parameter sources
      method_params = []

      method_params[0] = params[:id] if params[:id].present?

      if params[:query].present?
        method_params[0] = params[:query] if method_params[0].blank?
        method_params[1] = params[:limit] if params[:limit].present?
      elsif params[:title].present?
        method_params[0] = params[:title]
        method_params[1] = params[:description]
        method_params[2] = params[:html_content]
        method_params[3] = params[:author]
      elsif params[:key].present?
        method_params[0] = params[:key]
        method_params[1] = params[:value] if params[:value].present?
      elsif params[:updates].present?
        method_params[1] = params[:updates]
      end

      # Handle limit parameter for search
      method_params[1] = params[:limit].to_i if params[:limit].present? && method_params[1].blank?

      method_params.compact
    end

    def permitted_method?(method_name)
      method_name = method_name.to_s.strip

      # Methods requiring authentication
      authenticated_methods = %w[
        experiences.create
        experiences.update
        experiences.delete
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
        experiences.approve
        experiences.pending_approval
        moderation.get_logs
        admin.experiences.all
        admin.experiences.approve
      ]

      # Check if method exists at all
      all_methods = public_methods + authenticated_methods + admin_methods
      return false unless all_methods.include?(method_name)

      # Check authentication requirements
      return false if authenticated_methods.include?(method_name) && !current_account

      return false if admin_methods.include?(method_name) && !current_account&.admin?

      true
    end

    def process_method_call(method_name, params)
      case method_name
      when "experiences.all"
        # Get experiences; admins see all, others see only approved ones
        scope = current_account&.admin? ? Experience : Experience.approved
        @experiences = scope.order(created_at: :desc)
        render "api/json/experiences_all"

      when "experiences.get"
        experience_id = params[0]
        @experience = if current_account&.admin?
          Experience.find_by(id: experience_id)
        else
          Experience.approved.find_by(id: experience_id)
        end
        raise "Experience not found" unless @experience

        render "api/json/experience_get"

      when "experiences.approved"
        @experiences = Experience.approved.order(created_at: :desc)
        render "api/json/experiences_all"

      when "experiences.pending_approval"
        @experiences = Experience.pending_approval.order(created_at: :desc)
        render "api/json/experiences_pending_approval"

      when "experiences.create"
        title = params[0]
        description = params[1]
        html_content = params[2]
        author = params[3]

        raise "Title is required" if title.blank?
        raise "HTML content is required" if html_content.blank?

        @experience = Experience.new(
          title: title,
          description: description,
          author: author,
          account: current_account
        )

        # Use StringIO to keep content in memory instead of writing to disk
        html_io = StringIO.new(html_content)

        @experience.html_file.attach(
          io: html_io,
          filename: "#{title.parameterize}.html",
          content_type: "text/html"
        )

        raise "Failed to create experience: #{@experience.errors.full_messages.join(', ')}" unless @experience.save

        render "api/json/experience_create"

      when "experiences.update"
        experience_id = params[0]
        updates = params[1]

        @experience = Experience.find_by(id: experience_id, account_id: current_account.id)
        raise "Experience not found or not owned by current user" unless @experience

        update_params = {}
        update_params[:title] = updates["title"] if updates["title"].present?
        update_params[:description] = updates["description"] if updates["description"].present?
        update_params[:author] = updates["author"] if updates["author"].present?

        raise "Failed to update experience: #{@experience.errors.full_messages.join(', ')}" unless @experience.update(update_params)

        render "api/json/experience_update"

      when "experiences.delete"
        experience_id = params[0]
        experience = Experience.find_by(id: experience_id, account_id: current_account.id)
        raise "Experience not found or not owned by current user" unless experience

        raise "Failed to delete experience" unless experience.destroy

        render "api/json/experience_delete"

      when "experiences.approve"
        # Admin only
        experience_id = params[0]
        @experience = Experience.find_by(id: experience_id)
        raise "Experience not found" unless @experience

        raise "Failed to approve experience: #{@experience.errors.full_messages.join(', ')}" unless @experience.update(approved: true)

        render "api/json/experience_approve"

      when "preferences.get"
        @key = params[0]
        raise "Invalid preference key" unless UserPreference::ALLOWED_KEYS.include?(@key)

        @value = UserPreference.get(current_account.id, @key)
        render "api/json/preference_get"

      when "preferences.set"
        @key = params[0]
        @value = params[1]
        raise "Invalid preference key" unless UserPreference::ALLOWED_KEYS.include?(@key)

        @value = UserPreference.set(current_account.id, @key, @value)
        raise "Failed to set preference" unless @value

        render "api/json/preference_set"

      when "preferences.dismiss"
        @key = params[0]
        raise "Invalid preference key" unless UserPreference::ALLOWED_KEYS.include?(@key)

        result = UserPreference.dismiss(current_account.id, @key)
        raise "Failed to dismiss preference" unless result

        render "api/json/preference_dismiss"

      when "preferences.is_dismissed"
        key = params[0]
        raise "Invalid preference key" unless UserPreference::ALLOWED_KEYS.include?(key)

        @dismissed = UserPreference.dismissed?(current_account.id, key)
        render "api/json/preference_is_dismissed"

      when "account.get_info"
        @account = current_account
        @status = account_status_string(current_account.status)
        render "api/json/account_get_info"

      when "search.query", "search.public_query"
        query = params[0]
        limit = params[1]

        # Ensure limit is an integer
        limit = limit.present? ? [ limit.to_i, 100 ].min : 20

        scope = if method_name == "search.query" && current_account&.admin?
          Experience
        else
          Experience.approved
        end

        @experiences = if query.present?
          # Limit query length and sanitize
          query = query.to_s.strip[0...50]
          scope.where("title LIKE ?", "%#{sanitize_sql_like(query)}%")
               .order(created_at: :desc)
               .limit(limit)
        else
          scope.order(created_at: :desc).limit(limit)
        end

        render "api/json/search_query"

      when "moderation.get_logs"
        # Admin only or user's own logs
        @logs = if current_account&.admin?
          ModerationLog.recent.limit(100)
        else
          ModerationLog.where(account_id: current_account.id).recent.limit(100)
        end

        render "api/json/moderation_get_logs"

      when "admin.experiences.all"
        # Admin only
        @experiences = Experience.order(created_at: :desc)
        render "api/json/admin_experiences_all"

      when "admin.experiences.approve"
        # Admin only
        experience_id = params[0]
        @experience = Experience.find_by(id: experience_id)
        raise "Experience not found" unless @experience

        raise "Failed to approve experience: #{@experience.errors.full_messages.join(', ')}" unless @experience.update(approved: true)

        render "api/json/admin_experiences_approve"

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

    def apply_rate_limit
      key = "json_api_rate_limit:#{request.ip}"
      count = Rails.cache.increment(key, 1, expires_in: 1.minute)
      count ||= 1 # first hit returns nil on some back-ends

      return true unless count > 60 # Higher limit for JSON API

      @error_message = "Rate limit exceeded"
      render "api/json/error", status: :too_many_requests
      false # Halt the filter chain
    end

    def current_account
      @current_account ||= AccountSequel.where(id: session[:account_id]).first
    end

    def force_json_format
      request.format = :json
    end
  end
end
