# frozen_string_literal: true
# shareable_constant_value: literal

# This migration comes from federails (originally 20241002094500)
class AddUuids < ActiveRecord::Migration[7.0]
  def change
    %i[
      federails_actors
      federails_activities
      federails_followings
    ].each do |table|
      # Step 1: Add the uuid column as nullable without an index
      change_table table do |t|
        t.string :uuid, default: nil
      end

      # Step 2: Backfill existing rows with unique UUIDs in batches
      backfill_uuids(table)

      # Step 3: Add the null: false constraint and unique index
      change_table table do |t|
        t.change_null :uuid, false
        t.index :uuid, unique: true
      end
    end
  end

  private

  def backfill_uuids(table_name)
    # Use raw SQL to avoid model dependencies in migrations
    batch_size = 1000
    offset = 0

    loop do
      # Get a batch of records without UUIDs
      records = execute("SELECT id FROM #{table_name} WHERE uuid IS NULL LIMIT #{batch_size} OFFSET #{offset}")

      break if records.count.zero?

      # Update each record with a unique UUID
      records.each do |record|
        uuid = SecureRandom.uuid
        execute("UPDATE #{table_name} SET uuid = '#{uuid}' WHERE id = #{record['id']}")
      end

      offset += batch_size
    end
  end
end
