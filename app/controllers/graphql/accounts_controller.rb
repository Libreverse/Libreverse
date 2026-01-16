# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

module Graphql
  class AccountsController < GraphqlApplicationController
    model("GraphqlAccount")

    # Queries
    action(:me).returns("GraphqlAccount")

    def me
      require_authentication

      GraphqlAccount.new(current_account)
    end
  end
end
