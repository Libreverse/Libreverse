# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class AddModerationToComments < ActiveRecord::Migration[7.1]
  def change
    change_table :comments, bulk: true do |t|
      t.string :moderation_state, null: false, default: 'pending'
      t.datetime :approved_at
      t.bigint :approved_by_id
      t.json :moderation_flags
    end
    add_index :comments, :moderation_state
  end
end
