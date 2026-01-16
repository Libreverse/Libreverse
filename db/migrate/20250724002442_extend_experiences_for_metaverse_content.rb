# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class ExtendExperiencesForMetaverseContent < ActiveRecord::Migration[8.0]
  def change
    change_table :experiences, bulk: true do |t|
      # Source type to distinguish between user-created and indexed content
      t.string :source_type, default: 'user_created', null: false

      # Reference to indexed content (nullable for user-created experiences)
      t.references :indexed_content, null: true, foreign_key: true

      # Metaverse platform (for indexed content)
      t.string :metaverse_platform, null: true

      # Serialized coordinates data (for indexed content)
      t.text :metaverse_coordinates, null: true

      # Additional metaverse-specific metadata
      t.text :metaverse_metadata, null: true
    end

    # Add indexes for efficient querying
    add_index :experiences, :source_type
    add_index :experiences, :metaverse_platform
    add_index :experiences, %i[source_type metaverse_platform]
  end
end
