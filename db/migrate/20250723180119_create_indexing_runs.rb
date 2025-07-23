# frozen_string_literal: true

class CreateIndexingRuns < ActiveRecord::Migration[8.0]
  def change
    create_table :indexing_runs do |t|
      t.string :indexer_class, null: false
      t.integer :status, default: 0, null: false
      t.text :configuration
      t.integer :items_processed, default: 0
      t.integer :items_failed, default: 0
      t.datetime :started_at
      t.datetime :completed_at
      t.text :error_message
      t.text :error_details

      t.timestamps
    end

    # Add indexes for performance
    add_index :indexing_runs, :indexer_class
    add_index :indexing_runs, :status
    add_index :indexing_runs, :started_at
  end
end
