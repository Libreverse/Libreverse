require_relative "libreverse_pb"
require_relative "libreverse_services_pb"

module Libreverse
  module Grpc
    # Security concern for gRPC requests
    module GrpcSecurity
      extend ActiveSupport::Concern

      private

      def authenticated_account
        # Extract session/token from gRPC metadata
        metadata = request_metadata
        session_id = metadata["session-id"]&.first
        token = metadata["authorization"]&.first

        if session_id
          # Look up session (simplified - you'd need proper session handling)
          session_data = Rails.cache.read("session:#{session_id}")
          return nil unless session_data

          account_id = session_data["account_id"]
          return Account.find_by(id: account_id) if account_id
        elsif token
          # Handle bearer token authentication if implemented
          # This would need to be implemented based on your auth system
        end

        nil
      end

      def require_authentication!
        account = authenticated_account
        raise GRPC::PermissionDenied, "Authentication required" unless account

        account
      end

      def require_admin!
        account = require_authentication!
        raise GRPC::PermissionDenied, "Admin access required" unless account.admin?

        account
      end

      def request_metadata
        # This would be set by the gRPC framework
        @request_metadata ||= {}
      end
    end

    # Main gRPC service implementation
    class LibreverseServiceImpl < Libreverse::Grpc::LibreverseService::Service
      include GrpcSecurity

      # Experience management methods
      def get_all_experiences(_request, call)
          @request_metadata = call.metadata # <-- critical
          account = authenticated_account

          # Get experiences; admins see all, others see only approved ones
          scope = account&.admin? ? ::Experience : ::Experience.approved
          experiences = scope.order(created_at: :desc).limit(100) # Add reasonable limit

          grpc_experiences = experiences.map { |exp| experience_to_grpc(exp) }

          Libreverse::Grpc::ExperiencesResponse.new(
            experiences: grpc_experiences,
            success: true,
            message: "Experiences retrieved successfully"
          )
      rescue StandardError => e
          Rails.logger.error "gRPC GetAllExperiences error: #{e.message}"
          Libreverse::Grpc::ExperiencesResponse.new(
            experiences: [],
            success: false,
            message: "Failed to retrieve experiences: #{e.message}"
          )
      end

      def get_experience(request, _call)
          account = authenticated_account
          experience_id = request.id

          experience = if account&.admin?
            ::Experience.find_by(id: experience_id)
          else
            ::Experience.approved.find_by(id: experience_id)
          end

          raise GRPC::NotFound, "Experience with ID #{experience_id} not found or not accessible" unless experience

          Libreverse::Grpc::ExperienceResponse.new(
            experience: experience_to_grpc(experience),
            success: true,
            message: "Experience retrieved successfully"
          )
      end

      def create_experience(request, _call)
          account = require_authentication!

          experience = ::Experience.new(
            title: request.title,
            description: request.description,
            author: request.author,
            account: account
          )

          if experience.save
            Libreverse::Grpc::ExperienceResponse.new(
              experience: experience_to_grpc(experience),
              success: true,
              message: "Experience created successfully"
            )
          else
            Libreverse::Grpc::ExperienceResponse.new(
              success: false,
              message: "Failed to create experience: #{experience.errors.full_messages.join(', ')}"
            )
          end
      rescue GRPC::PermissionDenied => e
          raise e
      rescue StandardError => e
          Rails.logger.error "gRPC CreateExperience error: #{e.message}"
          Libreverse::Grpc::ExperienceResponse.new(
            success: false,
            message: "Failed to create experience: #{e.message}"
          )
      end

      def update_experience(request, _call)
          account = require_authentication!
          experience_id = request.id

          experience = ::Experience.find_by(id: experience_id, account_id: account.id)
          raise "Experience not found or not owned by current user" unless experience

          update_params = {}
          update_params[:title] = request.title if request.has_title?
          update_params[:description] = request.description if request.has_description?
          update_params[:author] = request.author if request.has_author?

          if experience.update(update_params)
            Libreverse::Grpc::ExperienceResponse.new(
              experience: experience_to_grpc(experience),
              success: true,
              message: "Experience updated successfully"
            )
          else
            Libreverse::Grpc::ExperienceResponse.new(
              success: false,
              message: "Failed to update experience: #{experience.errors.full_messages.join(', ')}"
            )
          end
      rescue GRPC::PermissionDenied => e
          raise e
      rescue StandardError => e
          Rails.logger.error "gRPC UpdateExperience error: #{e.message}"
          Libreverse::Grpc::ExperienceResponse.new(
            success: false,
            message: "Failed to update experience: #{e.message}"
          )
      end

      def delete_experience(request, _call)
          account = require_authentication!
          experience_id = request.id

          experience = ::Experience.find_by(id: experience_id, account_id: account.id)
          raise "Experience not found or not owned by current user" unless experience

          if experience.destroy
            Libreverse::Grpc::DeleteResponse.new(
              success: true,
              message: "Experience deleted successfully"
            )
          else
            Libreverse::Grpc::DeleteResponse.new(
              success: false,
              message: "Failed to delete experience"
            )
          end
      rescue GRPC::PermissionDenied => e
          raise e
      rescue StandardError => e
          Rails.logger.error "gRPC DeleteExperience error: #{e.message}"
          Libreverse::Grpc::DeleteResponse.new(
            success: false,
            message: "Failed to delete experience: #{e.message}"
          )
      end

      def approve_experience(request, _call)
          account = require_authentication!
          experience_id = request.id

          experience = ::Experience.find_by(id: experience_id, account_id: account.id)
          raise "Experience not found or not owned by current user" unless experience

          if experience.update(approved: true)
            Libreverse::Grpc::ExperienceResponse.new(
              experience: experience_to_grpc(experience),
              success: true,
              message: "Experience approved successfully"
            )
          else
            Libreverse::Grpc::ExperienceResponse.new(
              success: false,
              message: "Failed to approve experience: #{experience.errors.full_messages.join(', ')}"
            )
          end
      rescue GRPC::PermissionDenied => e
          raise e
      rescue StandardError => e
          Rails.logger.error "gRPC ApproveExperience error: #{e.message}"
          Libreverse::Grpc::ExperienceResponse.new(
            success: false,
            message: "Failed to approve experience: #{e.message}"
          )
      end

      def get_pending_experiences(_request, _call)
          account = require_authentication!

          experiences = ::Experience.where(account: account, approved: false)
                                    .order(created_at: :desc)
                                    .limit(100)

          grpc_experiences = experiences.map { |exp| experience_to_grpc(exp) }

          Libreverse::Grpc::ExperiencesResponse.new(
            experiences: grpc_experiences,
            success: true,
            message: "Pending experiences retrieved successfully"
          )
      rescue GRPC::PermissionDenied => e
          raise e
      rescue StandardError => e
          Rails.logger.error "gRPC GetPendingExperiences error: #{e.message}"
          Libreverse::Grpc::ExperiencesResponse.new(
            experiences: [],
            success: false,
            message: "Failed to retrieve pending experiences: #{e.message}"
          )
      end

      # User preferences methods
      def get_preference(request, _call)
          account = require_authentication!
          key = request.key

          raise "Invalid preference key" unless UserPreference::ALLOWED_KEYS.include?(key)

          value = UserPreference.get(account.id, key)

          Libreverse::Grpc::PreferenceResponse.new(
            key: key,
            value: value || "",
            success: true,
            message: "Preference retrieved successfully"
          )
      rescue GRPC::PermissionDenied => e
          raise e
      rescue StandardError => e
          Rails.logger.error "gRPC GetPreference error: #{e.message}"
          Libreverse::Grpc::PreferenceResponse.new(
            key: request.key,
            value: "",
            success: false,
            message: "Failed to retrieve preference: #{e.message}"
          )
      end

      def set_preference(request, _call)
          account = require_authentication!
          key = request.key
          value = request.value

          raise "Invalid preference key" unless UserPreference::ALLOWED_KEYS.include?(key)

          result = UserPreference.set(account.id, key, value)
          raise "Failed to set preference" unless result

          Libreverse::Grpc::PreferenceResponse.new(
            key: key,
            value: result,
            success: true,
            message: "Preference set successfully"
          )
      rescue GRPC::PermissionDenied => e
          raise e
      rescue StandardError => e
          Rails.logger.error "gRPC SetPreference error: #{e.message}"
          Libreverse::Grpc::PreferenceResponse.new(
            key: request.key,
            value: "",
            success: false,
            message: "Failed to set preference: #{e.message}"
          )
      end

      def dismiss_preference(request, _call)
          account = require_authentication!
          key = request.key

          raise "Invalid preference key" unless UserPreference::ALLOWED_KEYS.include?(key)

          result = UserPreference.dismiss(account.id, key)
          raise "Failed to dismiss preference" unless result

          Libreverse::Grpc::PreferenceResponse.new(
            key: key,
            value: result,
            success: true,
            message: "Preference dismissed successfully"
          )
      rescue GRPC::PermissionDenied => e
          raise e
      rescue StandardError => e
          Rails.logger.error "gRPC DismissPreference error: #{e.message}"
          Libreverse::Grpc::PreferenceResponse.new(
            key: request.key,
            value: "",
            success: false,
            message: "Failed to dismiss preference: #{e.message}"
          )
      end

      # Admin methods
      def admin_approve_experience(request, _call)
          require_admin!
          experience_id = request.id

          experience = ::Experience.find_by(id: experience_id)
          raise "Experience not found" unless experience

          if experience.update(approved: true)
            Libreverse::Grpc::ExperienceResponse.new(
              experience: experience_to_grpc(experience),
              success: true,
              message: "Experience approved successfully"
            )
          else
            Libreverse::Grpc::ExperienceResponse.new(
              success: false,
              message: "Failed to approve experience: #{experience.errors.full_messages.join(', ')}"
            )
          end
      rescue GRPC::PermissionDenied => e
          raise e
      rescue StandardError => e
          Rails.logger.error "gRPC AdminApproveExperience error: #{e.message}"
          Libreverse::Grpc::ExperienceResponse.new(
            success: false,
            message: "Failed to approve experience: #{e.message}"
          )
      end

      private

      def experience_to_grpc(experience)
        Libreverse::Grpc::Experience.new(
          id: experience.id,
          title: experience.title || "",
          description: experience.description || "",
          author: experience.author || "",
          approved: experience.approved || false,
          created_at: experience.created_at&.iso8601 || "",
          updated_at: experience.updated_at&.iso8601 || "",
          account_id: experience.account_id || 0
        )
      end
    end
  end
end
