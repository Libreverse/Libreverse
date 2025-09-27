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
