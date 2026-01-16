# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class CreateUserPreferences < ActiveRecord::Migration[7.0]
  def change
    create_table :user_preferences do |t|
      t.references :account, null: false, foreign_key: true
      t.string :key, null: false
      t.string :value
      t.timestamps
    end

    add_index :user_preferences, %i[account_id key], unique: true

    # Add a column to accounts table to track guest accounts
    add_column :accounts, :guest, :boolean, default: false
  end
end
