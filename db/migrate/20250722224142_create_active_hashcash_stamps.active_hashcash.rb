# frozen_string_literal: true

# This migration comes from active_hashcash (originally 20240215143453)
# Successful hashcash stamp are stored in the database.
# This migration creates the table for the model ActiveHashcash::Stamp.
# Run the following commands to add it to your Rails application:
#
#   rails active_hashcash:install:migrations
#   rails db:migrate
#
class CreateActiveHashcashStamps < ActiveRecord::Migration[5.2]
  def change
    create_table :active_hashcash_stamps do |t|
      t.string :version, null: false
      t.integer :bits, null: false
      t.date :date, null: false
      t.string :resource, null: false
      t.string :ext, null: false
      t.string :rand, null: false
      t.string :counter, null: false
      t.string :request_path
      t.string :ip_address

      if t.respond_to?(:jsonb)
        t.jsonb :context # SQLite JSONB support from version 3.45 (2024-01-15)
      elsif t.respond_to?(:json)
        t.json :context
      end

      t.timestamps
    end
    add_index :active_hashcash_stamps, %i[ip_address created_at], where: "ip_address IS NOT NULL"
    # Reduced index to fit TiDB/MySQL key length limits - counter + rand + date should be sufficient for uniqueness
    add_index :active_hashcash_stamps, %i[counter rand date resource], name: "index_active_hashcash_stamps_unique", unique: true
  end
end
