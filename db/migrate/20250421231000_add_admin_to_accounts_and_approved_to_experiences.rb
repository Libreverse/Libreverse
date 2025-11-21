# frozen_string_literal: true
# shareable_constant_value: literal

class AddAdminToAccountsAndApprovedToExperiences < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :admin, :boolean, null: false, default: false
    add_index :accounts, :admin

    add_column :experiences, :approved, :boolean, null: false, default: false
    add_index :experiences, :approved
  end
end
