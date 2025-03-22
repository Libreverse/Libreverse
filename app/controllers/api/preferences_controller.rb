module Api
  class PreferencesController < ApplicationController
    before_action :ensure_account
    before_action :validate_preference_key
    before_action :verify_authenticity_token
    before_action :apply_rate_limit

    # GET /api/preferences/is_dismissed
    def is_dismissed
      key = params[:key]
      dismissed = UserPreference.dismissed?(current_account.id, key)

      # Log the access for audit purposes
      Rails.logger.info "Preference check: account=#{current_account.id}, key=#{key}, dismissed=#{dismissed}, ip=#{request.ip}"

      render json: { dismissed: dismissed }, status: :ok
    end

    # POST /api/preferences/dismiss
    def dismiss
      key = params[:key]
      UserPreference.dismiss(current_account.id, key)

      # Log the dismissal for audit purposes
      Rails.logger.info "Preference dismissed: account=#{current_account.id}, key=#{key}, ip=#{request.ip}"

      render json: { success: true }, status: :ok
    end

    private

    # Apply a simple rate limit for API endpoints
    def apply_rate_limit
      key = "api_rate_limit:#{request.ip}:#{Time.now.to_i / 60}"
      count = Rails.cache.increment(key, 1, expires_in: 1.minute)

      return unless count > 30 # 30 requests per minute

        Rails.logger.warn "Rate limit exceeded for IP: #{request.ip}"
        render json: { error: "Rate limit exceeded" }, status: :too_many_requests
        false
    end

    # Validate the preference key to prevent abuse
    def validate_preference_key
      key = params[:key].to_s

      # Use the same allowed keys as defined in the model
      allowed_keys = UserPreference::ALLOWED_KEYS

      return if allowed_keys.include?(key)

        Rails.logger.warn "Invalid preference key attempted: #{key} from IP: #{request.ip}"
        render json: { error: "Invalid preference key" }, status: :bad_request
        false
    end

    # Ensure the user has an account (either logged in or guest)
    def ensure_account
      return if current_account

      begin
        # Try to create a guest account if not logged in
        rodauth.allow_guest
        Rails.logger.info "Created guest account: #{rodauth.session_value} for IP: #{request.ip}"
      rescue StandardError => e
        # Log the error but continue without preferences
        Rails.logger.error "Failed to create guest account: #{e.message}"
        render json: { error: "Could not store preference" }, status: :internal_server_error
        false
      end
    end

    # Get the current account from rodauth
    def current_account
      # Try to get the account ID from the session
      if rodauth.logged_in?
        Account.find_by(id: rodauth.session_value)
      elsif rodauth.guest_logged_in?
        Account.find_by(id: rodauth.session_value)
      end
    end

    # Allow access to rodauth methods
    def rodauth
      @rodauth ||= scope.rodauth
    end

    # Load the main Rodauth app
    def scope
      @scope ||= RodauthApp.new(request.env)
    end
  end
end
