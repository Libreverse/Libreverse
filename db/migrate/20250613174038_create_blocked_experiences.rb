# frozen_string_literal: true
# shareable_constant_value: literal

class CreateBlockedExperiences < ActiveRecord::Migration[8.0]
  def change
    create_table :blocked_experiences do |t|
      t.string :activitypub_uri, null: false
      t.text :reason
      t.datetime :blocked_at, null: false
      t.string :blocked_by

      t.timestamps
    end

    add_index :blocked_experiences, :activitypub_uri, unique: true
  end
end
