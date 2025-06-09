# frozen_string_literal: true

class CreateExperiencesVssTable < ActiveRecord::Migration[7.1]
  def up
    # Attempt to load VSS extension directly and explicitly for this migration
    begin
      db_connection = ActiveRecord::Base.connection.raw_connection
      db_connection.enable_load_extension(true)

      # Ensure sqlite_vss gem is required; it should be via Gemfile, but good practice.
      require 'sqlite_vss' unless defined?(SqliteVss)

      SqliteVss.load(db_connection)
      db_connection.enable_load_extension(false)
      Rails.logger.info "VSS extension loaded successfully for CreateExperiencesVssTable migration."
    rescue StandardError => e
      Rails.logger.error "CRITICAL: Failed to load VSS extension during CreateExperiencesVssTable migration: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
      raise "VSS extension could not be loaded, which is required to create the 'experiences_vss' virtual table. Error: #{e.message}"
    end

    # Optional: Verify VSS is loaded by checking version (good for confirmation)
    begin
      version_result = ActiveRecord::Base.connection.execute("SELECT vss_version();")
      # The result might be an array of hashes, e.g., [{"vss_version"=>"v0.1.2"}]
      # Adjust access to the version string as needed based on actual output.
      if version_result.is_a?(Array) && version_result.first.is_a?(Hash) && version_result.first.key?('vss_version')
        Rails.logger.info "VSS version confirmed after load: #{version_result.first['vss_version']}"
      else
        Rails.logger.info "VSS version query executed, result format unexpected: #{version_result.inspect}"
      end
    rescue SQLite3::SQLException => e
      Rails.logger.error "VSS version check failed even after explicit load attempt: #{e.message}. Virtual table creation is likely to fail."
      # Depending on strictness, you might re-raise here.
      # raise "VSS version check failed. Error: #{e.message}"
    end

    # Create the virtual table for vector search
    execute <<~SQL
      CREATE VIRTUAL TABLE IF NOT EXISTS experiences_vss USING vss0(
        embedding(#{VectorSearchService::DIMENSIONS})
      );
    SQL
    Rails.logger.info "Created virtual table 'experiences_vss' for vector search (or it already existed)."
  end

  def down
    execute "DROP TABLE IF EXISTS experiences_vss;"
    Rails.logger.info "Dropped virtual table 'experiences_vss'."
  end
end
