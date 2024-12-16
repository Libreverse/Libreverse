# app/controllers/search_controller.rb
class SearchController < ApplicationController
  include Turbo::Streams::ActionHelper

  def index
    @experience = Experience.new  # Initialize a new Experience for the form

    if params[:query].present?
      @experiences =
        Experience.where("title LIKE ?", "%#{params[:query]}%").order(
          created_at: :desc
        )
    else
      @experiences = Experience.all.order(created_at: :desc)
    end

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream:
                 turbo_stream.update(
                   "experiences_list",
                   partial: "experiences_list",
                   locals: {
                     experiences: @experiences
                   }
                 )
      end
    end
  end
end
