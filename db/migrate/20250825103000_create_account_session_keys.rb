# frozen_string_literal: true
# shareable_constant_value: literal

class CreateAccountSessionKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :account_session_keys, id: false do |t|
      t.primary_key :id, :bigint
      t.string :key, null: false
    end

    add_foreign_key :account_session_keys, :accounts, column: :id
  end
end
