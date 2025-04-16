# frozen_string_literal: true

# app/controllers/search_controller.rb
class SearchController < ApplicationController
  def index
    query = params[:query].to_s.strip
    # Cap query length and validate input
    query = query[0...50]

    @experiences = if query.present?
      # Use parameterized safe approach instead of LIKE with interpolation
      Experience.where("title LIKE ?", "%#{sanitize_sql_like(query)}%")
                .order(created_at: :desc)
                .limit(100)
    else
      Experience.order(created_at: :desc).limit(20)
    end
  end

  private

  # Sanitize SQL LIKE wildcards to prevent injection
  def sanitize_sql_like(str)
    # Escape LIKE special characters: %, _, [, ], ^
    str.gsub(/[%_\[\]\^\\]/) { |x| "\\#{x}" }
  end
end
