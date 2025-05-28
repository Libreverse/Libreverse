# frozen_string_literal: true

class GraphqlController < ApplicationController
  include XmlrpcSecurity

  # Ensure GraphQL responses are rendered without being hijacked by global HTML
  # filters (e.g. the privacy‑consent screen).
  skip_before_action :_enforce_privacy_consent, raise: false

  # Use null_session for GraphQL requests to avoid session reset but still protect against CSRF
  protect_from_forgery with: :null_session, if: -> { graphql_request? }
  protect_from_forgery with: :exception, unless: -> { graphql_request? }

  before_action :apply_rate_limit
  before_action :current_account
  before_action :verify_csrf_for_state_changing_methods

  def execute
    render json: GraphqlRails::QueryRunner.call(
      params: params,
      context: graphql_context
    )
  end

  private

  def graphql_request?
    request.path == "/graphql" && request.post? &&
      (request.content_type&.include?("application/json") ||
       request.content_type&.include?("application/graphql"))
  end

  def verify_csrf_for_state_changing_methods
    return true unless graphql_request?
    return true if Rails.env.test? && !request.headers["X-Test-CSRF"] # Skip CSRF in test environment unless explicitly testing

    # Parse GraphQL query to check if it contains mutations
    query_string = params[:query]
    return true if query_string.blank?

    # Check if this is a mutation (state-changing operation)
    if query_string.strip.start_with?("mutation")
      # For GraphQL mutations, check for X-CSRF-Token header
      token = request.headers["X-CSRF-Token"]

      unless token.present? && valid_authenticity_token?(session, token)
        render json: {
          errors: [ { message: "CSRF token missing or invalid" } ]
        }, status: :forbidden
        return false
      end
    end

    true
  end

  # data defined here will be accessible via `graphql_request.context`
  # in GraphqlRails::Controller instances
  def graphql_context
    {
      current_account: current_account,
      request: request
    }
  end

  def apply_rate_limit
    key = "graphql_rate_limit:#{request.ip}"
    count = Rails.cache.increment(key, 1, expires_in: 1.minute)

    return true unless count > 100 # Higher limit for GraphQL due to flexibility

    render json: {
      errors: [ { message: "Rate limit exceeded" } ]
    }, status: :too_many_requests
    false # Halt the filter chain
  end

  def current_account
    # Get account_id from session (handles both regular requests and test requests)
    account_id = session[:account_id] ||
                 request.env["rack.session"]&.[](:account_id)

    @current_account ||= account_id ? AccountSequel.where(id: account_id).first : nil
  end
end
