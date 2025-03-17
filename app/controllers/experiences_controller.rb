class ExperiencesController < ApplicationController
  before_action :set_experience, only: %i[show edit update destroy]

  # GET /experiences
  def index
    @experiences = Experience.all.order(created_at: :desc)
    @experience = Experience.new
  end

  # GET /experiences/1
  def show
  end

  # GET /experiences/new
  def new
    @experience = Experience.new
  end

  # POST /experiences
  def create
    @experience = Experience.new(experience_params)
    if @experience.save
      redirect_to experiences_path, notice: "Experience created successfully."
    else
      @experiences = Experience.all.order(created_at: :desc)
      render :index, status: :unprocessable_entity
    end
  end

  # GET /experiences/1/edit
  def edit
  end

  # PATCH/PUT /experiences/1
  def update
    if @experience.update(experience_params)
      redirect_to @experience, notice: "Experience was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /experiences/1
  def destroy
    @experience.destroy
    redirect_to experiences_path, notice: "Experience was successfully deleted."
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_experience
    @experience = Experience.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def experience_params
    params.require(:experience).permit(:title, :description, :author)
  end
end
