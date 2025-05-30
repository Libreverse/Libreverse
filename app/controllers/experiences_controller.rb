# frozen_string_literal: true

class ExperiencesController < ApplicationController
  before_action :require_authentication
  before_action :set_experience, only: %i[show edit update destroy display approve]
  before_action :check_ownership, only: %i[edit update destroy]
  before_action :require_admin, only: %i[approve]

  # GET /experiences
  def index
    @experiences = if current_account&.admin?
      Experience.order(created_at: :desc)
    else
      Experience.approved.order(created_at: :desc)
    end
    @experience = Experience.new
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

  # GET /experiences/1/display
  def display
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
    params.require(:experience).permit(:title, :description, :html_file)
  end

  def require_admin
    unless current_account&.admin?
      flash[:alert] = "You must be an admin to perform that action."
      redirect_to experiences_path
      return false
    end
    true
  end
end
