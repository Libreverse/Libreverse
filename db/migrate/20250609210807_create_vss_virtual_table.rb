# frozen_string_literal: true

class CreateVssVirtualTable < ActiveRecord::Migration[8.0]
  def up
    # Ensure VSS extension is loaded
    connection = ActiveRecord::Base.connection

    begin
      # Load VSS extension manually for this migration
      raw_conn = connection.raw_connection
      raw_conn.enable_load_extension(true)
      require 'sqlite_vss'
      SqliteVss.load(raw_conn)
      raw_conn.enable_load_extension(false)

      # Create the VSS virtual table for experience embeddings
      execute <<~SQL
        CREATE VIRTUAL TABLE experiences_vss USING vss0(
          embedding(384)
        );
      SQL

      # Create an index table to map VSS rowids to experience IDs
      create_table :experience_vss_mappings do |t|
        t.integer :experience_id, null: false
        t.integer :vss_rowid, null: false
        t.timestamps
      end

      add_index :experience_vss_mappings, :experience_id, unique: true
      add_index :experience_vss_mappings, :vss_rowid, unique: true

      Rails.logger.debug "✅ VSS virtual table created successfully"
    rescue StandardError => e
      Rails.logger.debug "⚠️ Could not create VSS virtual table: #{e.message}"
      Rails.logger.debug "   This is okay - vector search will fall back to text search"
    end
  end

  def down
      # Drop the mapping table
      drop_table :experience_vss_mappings if table_exists?(:experience_vss_mappings)

      # Drop the VSS virtual table
      execute "DROP TABLE IF EXISTS experiences_vss;"

      Rails.logger.debug "✅ VSS virtual table dropped successfully"
  rescue StandardError => e
      Rails.logger.debug "⚠️ Could not drop VSS virtual table: #{e.message}"
  end
end
