# frozen_string_literal: true

class AddFederatedBlockedToExperiences < ActiveRecord::Migration[8.0]
  def change
    add_column :experiences, :federated_blocked, :boolean, default: false, null: false
  end
end
