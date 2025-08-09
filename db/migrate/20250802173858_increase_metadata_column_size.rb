# frozen_string_literal: true

class IncreaseMetadataColumnSize < ActiveRecord::Migration[8.0]
  def up
    # Change metadata column from TEXT to LONGTEXT to handle large Decentraland scene metadata
    change_column :indexed_contents, :metadata, :text, limit: 4_294_967_295
  end

  def down
    # Revert to standard TEXT column (65,535 characters)
    change_column :indexed_contents, :metadata, :text
  end
end
