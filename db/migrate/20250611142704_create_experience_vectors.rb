# frozen_string_literal: true
# shareable_constant_value: literal

class CreateExperienceVectors < ActiveRecord::Migration[8.0]
  def change
    create_table :experience_vectors do |t|
      t.references :experience, null: false, foreign_key: true, index: { unique: true }
      t.text :vector_data, null: false
      t.string :vector_hash, null: false
      t.datetime :generated_at, null: false
      t.integer :version, default: 1, null: false

      t.timestamps
    end

    add_index :experience_vectors, :vector_hash
    add_index :experience_vectors, :generated_at
  end
end
