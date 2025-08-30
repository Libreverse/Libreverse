# frozen_string_literal: true

require "grpc"

module Api
  class GrpcController < ApplicationController
    # Skip CSRF protection for gRPC requests since they use different auth
    skip_before_action :verify_authenticity_token

    # Short-circuit if gRPC is disabled at the instance level
    before_action :ensure_grpc_enabled
    before_action :validate_content_type
    before_action :apply_rate_limit, if: -> { response.status == 200 }
    before_action :set_no_cache_headers, if: -> { response.status == 200 }
    before_action :load_grpc_dependencies, if: -> { response.status == 200 }

    # POST /api/grpc
    def endpoint
        # Get the method and request data from params
        method_name = params[:method]
        request_data = (params[:request] || {}).permit!.to_h.deep_symbolize_keys

        # Validate method name
        if method_name.blank?
          render json: { error: "Method name is required" }, status: :bad_request
          return
        end

        # Create a mock gRPC call context
        call_context = OpenStruct.new(metadata: extract_metadata_from_headers)

        # Initialize the service
        service = Libreverse::Grpc::LibreverseServiceImpl.new

        # Set the request metadata for authentication
        service.instance_variable_set(:@request_metadata, call_context.metadata)

        # Call the appropriate method
        response = case method_name
        when "GetAllExperiences"
          request = Libreverse::Grpc::GetAllExperiencesRequest.new
          service.get_all_experiences(request, call_context)
        when "GetExperience"
          request = Libreverse::Grpc::GetExperienceRequest.new(request_data)
          service.get_experience(request, call_context)
        when "CreateExperience"
          request = Libreverse::Grpc::CreateExperienceRequest.new(request_data)
          service.create_experience(request, call_context)
        when "UpdateExperience"
          request = Libreverse::Grpc::UpdateExperienceRequest.new(request_data)
          service.update_experience(request, call_context)
        when "DeleteExperience"
          request = Libreverse::Grpc::DeleteExperienceRequest.new(request_data)
          service.delete_experience(request, call_context)
        when "ApproveExperience"
          request = Libreverse::Grpc::ApproveExperienceRequest.new(request_data)
          service.approve_experience(request, call_context)
        when "GetPendingExperiences"
          request = Libreverse::Grpc::GetPendingExperiencesRequest.new
          service.get_pending_experiences(request, call_context)
        when "GetPreference"
          request = Libreverse::Grpc::GetPreferenceRequest.new(request_data)
          service.get_preference(request, call_context)
        when "SetPreference"
          request = Libreverse::Grpc::SetPreferenceRequest.new(request_data)
          service.set_preference(request, call_context)
        when "DismissPreference"
          request = Libreverse::Grpc::DismissPreferenceRequest.new(request_data)
          service.dismiss_preference(request, call_context)
        when "AdminApproveExperience"
          request = Libreverse::Grpc::AdminApproveExperienceRequest.new(request_data)
          service.admin_approve_experience(request, call_context)
        else
          render json: { error: "Unknown method: #{method_name}" }, status: :bad_request
          return
        end

        # Convert protobuf response to JSON
        render json: response.to_h
    rescue GRPC::PermissionDenied => e
        render json: { error: e.message }, status: :unauthorized
    rescue GRPC::InvalidArgument => e
        render json: { error: e.message }, status: :bad_request
    rescue GRPC::NotFound => e
        render json: { error: e.message }, status: :not_found
    rescue StandardError => e
        Rails.logger.error "gRPC HTTP endpoint error: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render json: { error: "Internal server error" }, status: :internal_server_error
    end

    private

    def ensure_grpc_enabled
      return true if LibreverseInstance::Application.grpc_enabled?

      render json: { error: "gRPC service disabled" }, status: :service_unavailable
      false
    end

    def load_grpc_dependencies
      # Load gRPC files only when needed to avoid boot issues
      unless defined?(Libreverse::Grpc::LibreverseServiceImpl)
        grpc_path = Rails.root.join("app/grpc")
        require_dependency File.join(grpc_path, "libreverse_pb.rb")

        # Fix the require path in the services file
        services_file = File.join(grpc_path, "libreverse_services_pb.rb")
        services_content = File.read(services_file)
        if services_content.include?("require 'libreverse_pb'")
          services_content.gsub!("require 'libreverse_pb'", "require_relative 'libreverse_pb'")
          File.write(services_file, services_content)
        end

        require_dependency services_file
        require_dependency File.join(grpc_path, "libreverse_service.rb")
      end
    rescue LoadError => e
      Rails.logger.error "Failed to load gRPC dependencies: #{e.message}"
      render json: { error: "gRPC service unavailable" }, status: :service_unavailable
    end

    def set_no_cache_headers
      response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, private"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "0"
    end

    def validate_content_type
      valid_types = [ "application/json", "application/x-protobuf" ]

      unless valid_types.any? { |type| request.content_type&.include?(type) }
        render json: { error: "Unsupported content type. Use application/json or application/x-protobuf" },
               status: :unsupported_media_type
        return false
      end

      true
    end

    def extract_metadata_from_headers
      metadata = {}

      # Extract session ID from cookie or header
      if cookies[:session_id]
        metadata["session-id"] = [ cookies[:session_id] ]
      elsif request.headers["X-Session-ID"]
        metadata["session-id"] = [ request.headers["X-Session-ID"] ]
      end

      # Extract authorization token
      metadata["authorization"] = [ request.headers["Authorization"] ] if request.headers["Authorization"]

      metadata
    end

    def apply_rate_limit
      key = "grpc_rate_limit:#{request.ip}"
      count = Rails.cache.increment(key, 1, expires_in: 1.minute)

      return true unless count > Libreverse::GrpcConfig::RATE_LIMIT

      render json: { error: "Rate limit exceeded" }, status: :too_many_requests
      false # Halt the filter chain
    end
  end
end
