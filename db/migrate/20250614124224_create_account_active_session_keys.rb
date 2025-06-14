# frozen_string_literal: true

class CreateAccountActiveSessionKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :account_active_session_keys, id: false do |t|
      t.bigint :account_id, null: false
      t.string :session_id, null: false
      t.datetime :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.datetime :last_use, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    end

    add_index :account_active_session_keys, %i[account_id session_id], unique: true
    add_index :account_active_session_keys, :session_id, unique: true
    add_foreign_key :account_active_session_keys, :accounts, column: :account_id
  end
end
