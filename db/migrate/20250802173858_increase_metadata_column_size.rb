class IncreaseMetadataColumnSize < ActiveRecord::Migration[8.0]
  def change
    # Change metadata column from TEXT to LONGTEXT to handle large Decentraland scene metadata
    change_column :indexed_contents, :metadata, :text, limit: 4294967295
  end
end
