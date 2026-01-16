# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class CreateModerationLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :moderation_logs do |t|
      t.string :field
      t.string :model_type
      t.text :content
      t.string :reason
      t.references :account, null: true, foreign_key: true
      t.text :violations_data

      t.timestamps
    end
  end
end
