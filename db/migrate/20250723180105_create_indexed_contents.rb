# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

class CreateIndexedContents < ActiveRecord::Migration[8.0]
  def change
    create_table :indexed_contents do |t|
      t.string :source_platform, null: false
      t.string :external_id, null: false
      t.string :content_type, null: false
      t.string :title
      t.text :description
      t.string :author
      t.text :metadata
      t.text :coordinates
      t.datetime :last_indexed_at

      t.timestamps
    end

    # Add indexes for performance
    add_index :indexed_contents, %i[source_platform external_id], unique: true
    add_index :indexed_contents, :content_type
    add_index :indexed_contents, :last_indexed_at
    add_index :indexed_contents, :source_platform
  end
end
