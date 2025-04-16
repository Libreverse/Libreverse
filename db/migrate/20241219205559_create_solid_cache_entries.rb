# frozen_string_literal: true

class CreateSolidCacheEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :solid_cache_entries do |t|
      t.binary   :key,       limit: 1024, null: false
      t.binary   :value,     limit: 536_870_912, null: false
      t.datetime :created_at,                    null: false
      t.bigint   :key_hash,                      null: false
      t.integer  :byte_size,                     null: false
    end

    add_index :solid_cache_entries, :byte_size
    add_index :solid_cache_entries, %i[key_hash byte_size], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    add_index :solid_cache_entries, :key_hash, unique: true
  end
end
