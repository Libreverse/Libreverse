# frozen_string_literal: true

# app/controllers/search_controller.rb
class SearchController < ApplicationController
  def index
    query = params[:query].to_s.strip
    # Cap query length and validate input
    query = query[0...50]

    scope = current_account&.admin? ? Experience : Experience.approved
@experiences = if query.present?
      scope.where("title LIKE ?", "%#{sanitize_sql_like(query)}%")
           .order(created_at: :desc)
           .limit(100)
else
      scope.order(created_at: :desc).limit(20)
end
  end

  private

  # Sanitize SQL LIKE wildcards to prevent injection
  def sanitize_sql_like(str)
    # Escape LIKE special characters: %, _, [, ], ^
    str.gsub(/[%_\[\]\^\\]/) { |x| "\\#{x}" }
  end
end
