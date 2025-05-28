# frozen_string_literal: true

module Api
  class JsonController < ApplicationController
    include XmlrpcSecurity

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

    # GET/POST /api/json/:method
    def endpoint
      method_name = params[:method]

      # Validate method name format (no consecutive dots, must start/end with alphanumeric, allow underscores)
      unless method_name.present? && method_name.match?(/\A[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)*\z/)
        render json: { error: "Invalid method name" }, status: :bad_request
        return
      end

      # Validate permissions for the method
      unless permitted_method?(method_name)
        render json: { error: "Method not allowed" }, status: :forbidden
        return
      end

      # Extract parameters from request
      method_params = extract_params

      begin
        # Apply a processing timeout
        result = nil
        ActiveSupport::Notifications.instrument("json_api.process") do
          result = process_method_call(method_name, method_params)
        end
        # Rack / Puma request_timeout middleware or nginx proxy_timeout
        # should already enforce an upper bound on total request time.
        if result.nil?
          render json: { error: "Method processing failed" }, status: :internal_server_error
        else
          render json: { result: result }
        end
      rescue Timeout::Error
        render json: { error: "Request timeout" }, status: :request_timeout
      rescue StandardError => e
        Rails.logger.error("JSON API error: #{e.message}")
        render json: { error: "Internal server error" }, status: :internal_server_error
      end
    end

    private

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
          render json: { error: "CSRF token missing or invalid" }, status: :forbidden
          return false
        end
      end

      true
    end

    def validate_content_type
      return true if params[:method].present? # Allow URL parameter method calls

      valid_types = [ "application/json", "text/json" ]

      unless valid_types.any? { |type| request.content_type&.include?(type) }
        render json: { error: "Unsupported content type. Use application/json" },
               status: :unsupported_media_type
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
        experiences.all_with_unapproved
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

        experience = Experience.new(
          title: title,
          description: description,
          author: author,
          account_id: current_account.id
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
        { "dismissed" => dismissed }

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
        limit = params[1]

        # Ensure limit is an integer
        limit = limit.present? ? [ limit.to_i, 100 ].min : 20

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

      end
    end

    # Helper method to serialize experiences into a format suitable for JSON
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
        "created_at" => experience.created_at.iso8601,
        "updated_at" => experience.updated_at.iso8601
      }
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

    def apply_rate_limit
      key = "json_api_rate_limit:#{request.ip}"
      count = Rails.cache.increment(key, 1, expires_in: 1.minute)
      count ||= 1 # first hit returns nil on some back-ends

      return true unless count > 60 # Higher limit for JSON API

      render json: { error: "Rate limit exceeded" }, status: :too_many_requests
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
