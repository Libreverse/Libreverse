# frozen_string_literal: true

namespace :cache do
  desc "Set up SQLite cache database"
  task setup: :environment do
    puts "Setting up SQLite cache database..."

    # Create the database directory if it doesn't exist
    FileUtils.mkdir_p(File.dirname("db/cache_development.sqlite3"))
    FileUtils.mkdir_p(File.dirname("db/cache_test.sqlite3"))
    FileUtils.mkdir_p(File.dirname("db/cache_production.sqlite3"))

    # Create database connections for each environment
    %w[development test production].each do |env|
      database_file = "db/cache_#{env}.sqlite3"
      puts "Creating cache database for #{env} environment: #{database_file}"

      # Establish connection to the cache database
      config = {
        adapter: "sqlite3",
        database: database_file,
        pool: 5,
        timeout: 5000
      }

      # Create connection and run schema
      ActiveRecord::Base.establish_connection(config)
      connection = ActiveRecord::Base.connection

      # Create the solid_cache_entries table
      connection.create_table "solid_cache_entries", force: :cascade do |t|
        t.binary "key", limit: 1024, null: false
        t.binary "value", limit: 536_870_912, null: false
        t.datetime "created_at", null: false
        t.integer "key_hash", limit: 8, null: false
        t.integer "byte_size", limit: 4, null: false
        t.index [ "byte_size" ], name: "index_solid_cache_entries_on_byte_size"
        t.index %w[key_hash byte_size], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
        t.index [ "key_hash" ], name: "index_solid_cache_entries_on_key_hash", unique: true
      end

      puts "✓ Created cache database for #{env}"
    end

    puts "Cache databases setup complete!"
  end
end
