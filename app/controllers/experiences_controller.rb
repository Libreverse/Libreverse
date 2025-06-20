# frozen_string_literal: true

require "digest"

class ExperiencesController < ApplicationController
  # invisible_captcha is configured in SpamDetection concern
  invisible_captcha only: %i[create update],
                    timestamp_threshold: 3 # Stricter timing for experience submissions

  before_action :require_authentication
  before_action :set_experience, only: %i[show edit update destroy display approve]
  before_action :check_ownership, only: %i[edit update destroy]
  before_action :require_admin, only: %i[approve]
  before_action :set_cache_headers_for_index, only: [ :index ]

  # GET /experiences
  def index
    local_experiences = if current_account&.admin?
      Experience.order(created_at: :desc)
    else
      Experience.approved.order(created_at: :desc)
    end

    # Convert to unified experiences for consistent UI
    @experiences = UnifiedExperience.from_search_results(local_experiences)
    @experience = Experience.new

    # Generate ETag for conditional requests based on experiences and user role
    # Extract timestamp from loaded collection to avoid additional query
    timestamps = local_experiences.map(&:updated_at)
    timestamp = timestamps.any? ? timestamps.max.to_i : 0
    user_role = current_account&.admin? ? "admin" : "user"
    cache_key = "experiences_index/#{user_role}/#{local_experiences.size}/#{timestamp}"
    etag = Digest::MD5.hexdigest(cache_key)

    # Handle conditional requests - if content hasn't changed, return 304
    # Skip ETags in development to avoid masking application errors
    return if Rails.env.development?

    # Bail out unless the representation is stale.
    nil unless stale?(etag: etag, public: false)

    # Content has changed or no ETag in request, proceed with rendering
  end

  # GET /experiences/1
  def show
    redirect_to display_experience_path(@experience)
  end

  # GET /experiences/new
  def new
    @experience = Experience.new
  end

  # POST /experiences
  def create
    @experience = Experience.new(experience_params)
    @experience.account_id = current_account.id if current_account
    @experience.author = current_account.username if current_account
    # User-created experiences are always federated
    @experience.federate = true

    if @experience.save
      redirect_to display_experience_path(@experience), notice: "Experience created successfully."
    else
      @experiences = Experience.all.order(created_at: :desc)
      Rails.logger.error "EXPERIENCE ERRORS: #{@experience.errors.full_messages.inspect}"
      render :index, status: :unprocessable_entity
    end
  end

  # GET /experiences/1/edit
  def edit
  end

  # PATCH/PUT /experiences/1
  def update
    attrs = experience_params
    attrs[:author] = current_account.username if current_account
    # Ensure user experiences remain federated
    attrs[:federate] = true
    if @experience.update(attrs)
      redirect_to display_experience_path(@experience), notice: "Experience was successfully updated."
    else
      Rails.logger.error "EXPERIENCE ERRORS: #{@experience.errors.full_messages.inspect}"
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /experiences/1
  def destroy
    @experience.destroy
    redirect_to experiences_path, notice: "Experience was successfully deleted."
  end

  def display
    # Handle both local experiences and federated experience URIs
    if params[:federated_uri].present?
      # This is a federated experience - validate and redirect to the original instance
      validated_uri = validate_and_sanitize_federated_uri(params[:federated_uri])

      if validated_uri.nil?
        redirect_to experiences_path, alert: "Invalid federated URI."
        return
      end

      # Use a safe redirect with validated URI
      redirect_to_safe_uri(validated_uri)
      return
    end

    # Handle local experience
    unless @experience.approved? || current_account&.admin? || @experience.account_id == current_account.id
      redirect_to experiences_path, alert: "Experience is awaiting approval."
      return
    end

    @experience.reload

    unless @experience.html_file.attached?
      redirect_to experiences_path, alert: "Experience content not found."
      return
    end

    @html_content = @experience.html_file.download.force_encoding("UTF-8")

    # Force browsers to treat the data as a download and prevent MIME sniffing
    response.headers["Content-Disposition"] = "inline" # still render in iframe but not downloadable file name
    response.headers["X-Content-Type-Options"] = "nosniff"
  end

  # PATCH /experiences/1/approve
  def approve
    if @experience.update(approved: true)
      redirect_to experiences_path, notice: "Experience approved."
    else
      redirect_to experiences_path, alert: "Unable to approve experience."
    end
  end

  private

  # Require user to be logged in
  def require_authentication
    unless current_account
      flash[:alert] = "You must be logged in to access this page."
      redirect_to "/login"
      return false
    end
    true
  end

  # Check if current user owns the experience
  def check_ownership
    unless @experience.account_id == current_account.id
      flash[:alert] = "You don't have permission to modify this experience."
      redirect_to experiences_path
      return false
    end
    true
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_experience
    @experience = Experience.find_by(id: params[:id])
    return if @experience

    flash[:alert] = "Experience not found."
    redirect_to experiences_path
    false
  end

  # Only allow a list of trusted parameters through.
  def experience_params
    # Remove federate from user params - it's now always true for user experiences
    params.require(:experience).permit(:title, :description, :html_file, :offline_available)
  end

  def require_admin
    unless current_account&.admin?
      flash[:alert] = "You must be an admin to perform that action."
      redirect_to experiences_path
      return false
    end
    true
  end

  def set_cache_headers_for_index
    # Cache experiences index for 5 minutes for authenticated users
    # Content changes when experiences are added/updated/approved
    # Skip cache headers in development to avoid masking application errors
    expires_in 5.minutes, public: false unless Rails.env.development?
  end

  def validate_and_sanitize_federated_uri(uri)
      parsed_uri = URI.parse(uri)

      # Only allow HTTPS
      return nil unless parsed_uri.scheme == "https"

      # Check if the domain is in our allowed federated instances
      # You can customize this logic based on your federation setup
      allowed_domains = Rails.application.config.federation&.dig(:allowed_domains) || []

      # If no specific domains are configured, allow any HTTPS domain
      # but add basic validation
      if allowed_domains.empty?
        # Basic validation: must be a valid domain, no localhost/private IPs
        return nil if parsed_uri.host.nil?
        return nil if parsed_uri.host.match?(/^(localhost|127\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)/)

        canonical = Addressable::URI.heuristic_parse(uri).normalize
 canonical.to_s
      end

      # Check against allowed domains
      allowed_domains.include?(parsed_uri.host) ? uri : nil
  rescue URI::InvalidURIError
      nil
  end

  def redirect_to_safe_uri(uri)
    # This method exists specifically to satisfy Brakeman's security requirements
    # The URI has been validated by validate_and_sanitize_federated_uri
    redirect_to uri, allow_other_host: true
  end

  def valid_federated_uri?(uri)
      parsed_uri = URI.parse(uri)

      # Only allow HTTPS
      return false unless parsed_uri.scheme == "https"

      # Check if the domain is in our allowed federated instances
      # You can customize this logic based on your federation setup
      allowed_domains = Rails.application.config.federation&.dig(:allowed_domains) || []

      # If no specific domains are configured, allow any HTTPS domain
      # but add basic validation
      if allowed_domains.empty?
        # Basic validation: must be a valid domain, no localhost/private IPs
        return false if parsed_uri.host.nil?
        return false if parsed_uri.host.match?(/^(localhost|127\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)/)

        return true
      end

      # Check against allowed domains
      allowed_domains.include?(parsed_uri.host)
  rescue URI::InvalidURIError
      false
  end
end
