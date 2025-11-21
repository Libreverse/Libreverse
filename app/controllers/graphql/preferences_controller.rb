# frozen_string_literal: true
# shareable_constant_value: literal

module Graphql
  class PreferencesController < GraphqlApplicationController
    model("UserPreference")

    # Queries
    action(:get).permit(key: "String!").returns("UserPreference")
    action(:dismissed?).permit(key: "String!").returns("Boolean")

    # Mutations
    action(:set).permit(key: "String!", value: "String!").returns("UserPreference!")
    action(:dismiss).permit(key: "String!").returns("Boolean")

    def get
      require_authentication

      key = params[:key]
      raise GraphqlRails::ExecutionError, "Invalid preference key" unless UserPreference::ALLOWED_KEYS.include?(key)

      preference = UserPreference.find_by(account_id: current_account.id, key: key)
      preference || UserPreference.new(account_id: current_account.id, key: key, value: nil)
    end

    def dismissed?
      require_authentication

      key = params[:key]
      raise GraphqlRails::ExecutionError, "Invalid preference key" unless UserPreference::ALLOWED_KEYS.include?(key)

      UserPreference.dismissed?(current_account.id, key)
    end

    def set
      require_authentication

      key = params[:key]
      value = params[:value]

      raise GraphqlRails::ExecutionError, "Invalid preference key" unless UserPreference::ALLOWED_KEYS.include?(key)

      result = UserPreference.set(current_account.id, key, value)
      raise GraphqlRails::ExecutionError, "Failed to set preference" unless result

      # Return the updated/created preference
      UserPreference.find_by(account_id: current_account.id, key: key)
    end

    def dismiss
      require_authentication

      key = params[:key]
      raise GraphqlRails::ExecutionError, "Invalid preference key" unless UserPreference::ALLOWED_KEYS.include?(key)

      result = UserPreference.dismiss(current_account.id, key)
      raise GraphqlRails::ExecutionError, "Failed to dismiss preference" unless result

      true
    end
  end
end
