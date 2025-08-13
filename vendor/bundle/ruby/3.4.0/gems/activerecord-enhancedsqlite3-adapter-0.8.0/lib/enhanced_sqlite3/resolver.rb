# frozen_string_literal: true

module EnhancedSQLite3
  class Resolver < ActiveRecord::Middleware::DatabaseSelector::Resolver
    def reading_request?(request)
      true
    end
  end
end
