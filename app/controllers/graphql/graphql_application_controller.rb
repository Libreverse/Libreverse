# frozen_string_literal: true

module Graphql
  # base class of all GraphqlControllers
  class GraphqlApplicationController < GraphqlRails::Controller
    protected

    def current_account
      graphql_request.context[:current_account]
    end

    def require_authentication
      return true if current_account && !current_account.guest?

      raise GraphQL::ExecutionError, "Authentication required"
    end

    def require_admin
      require_authentication
      return true if current_account&.admin?

      raise GraphQL::ExecutionError, "Admin access required"
    end

    def sanitize_sql_like(str)
      ActiveRecord::Base.sanitize_sql_like(str)
    end

    def account_status_string(status)
      case status
      when 1 then "unverified"
      when 2 then "verified"
      when 3 then "closed"
      else "unknown"
      end
    end
  end
end
