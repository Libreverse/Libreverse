# app/controllers/search_controller.rb
class SearchController < ApplicationController
  def index
    query = params[:query].to_s.strip
    @experiences = if query.present?
                     Experience.where("title LIKE ?", "%#{query}%")
                               .order(created_at: :desc)
    else
                     Experience.all.order(created_at: :desc)
    end
    @experience = Experience.new
  end
end
