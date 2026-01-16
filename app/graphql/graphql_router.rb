# typed: false
# frozen_string_literal: true
# shareable_constant_value: none

GraphqlRouter = GraphqlRails::Router.draw do
  scope module: :graphql do
    # Experience operations
    resources :experiences do
      query :approved, on: :collection
      query :pending_approval, on: :collection
      mutation :approve, on: :member
    end

    # Account operations
    query :me, to: "accounts#me"

    # User preference operations
    query :get_preference, to: "preferences#get"
    query :is_dismissed, to: "preferences#dismissed?"
    mutation :set_preference, to: "preferences#set"
    mutation :dismiss_preference, to: "preferences#dismiss"

    # Moderation log operations
    query :moderation_logs, to: "moderation_logs#index"

    # Search operations
    query :search_experiences, to: "search#experiences"
  end
end
