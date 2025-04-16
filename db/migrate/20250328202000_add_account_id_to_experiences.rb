# frozen_string_literal: true

class AddAccountIdToExperiences < ActiveRecord::Migration[8.0]
  def change
    add_reference :experiences, :account, foreign_key: true
    add_index :experiences, %i[account_id created_at]
  end
end
