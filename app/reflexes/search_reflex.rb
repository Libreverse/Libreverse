# frozen_string_literal: true

class SearchReflex < ApplicationReflex
  def perform
    query = element[:value].to_s.strip
    query = query[0...50] # Cap the query length to 50 characters
    @experiences = if query.present?
      Experience.where("title ILIKE ?", "%#{query}%")
                .order(created_at: :desc)
    else
      Experience.all.order(created_at: :desc)
    end

    # Morph the experiences_list div with the new content
    morph "#experiences_list", ApplicationController.render(
      partial: "search/experiences_list",
      locals: { experiences: @experiences }
    )
  end
end
