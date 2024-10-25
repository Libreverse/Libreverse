# app/controllers/search_controller.rb
class SearchController < ApplicationController
  include Turbo::Streams::ActionHelper
  
  def index
    if params[:search].present?
      @experiences = Experience.where("content LIKE ?", "%#{params[:search]}%").order(created_at: :desc)
    else
      @experiences = Experience.all.order(created_at: :desc)
    end
    
    
    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.update('experiences_list', 
          partial: 'experiences_list', 
          locals: { experiences: @experiences }
        )
      end
    end
  end


  def create
    @experience = Experience.new(experience_params)
    if @experience.save
      redirect_to search_path, notice: 'Experience was successfully created.'
    else
      @experiences = Experience.all.order(created_at: :desc) # Reload experiences if there's an error
      render :index
    end
  end
end