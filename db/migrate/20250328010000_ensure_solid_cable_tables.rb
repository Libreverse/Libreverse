class EnsureSolidCableTables < ActiveRecord::Migration[8.0]
  def change
    # Only create the table if it doesn't exist
    unless table_exists?(:solid_cable_messages)
      create_table :solid_cable_messages, force: :cascade do |t|
        t.binary :channel, limit: 1024, null: false
        t.binary :payload, limit: 536870912, null: false
        t.datetime :created_at, null: false
        t.integer :channel_hash, limit: 8, null: false
        
        t.index [:channel], name: :index_solid_cable_messages_on_channel
        t.index [:channel_hash], name: :index_solid_cable_messages_on_channel_hash
        t.index [:created_at], name: :index_solid_cable_messages_on_created_at
      end
    end
    
    # Recreate indexes if they're missing
    unless index_exists?(:solid_cable_messages, :channel)
      add_index :solid_cable_messages, :channel, name: :index_solid_cable_messages_on_channel
    end
    
    unless index_exists?(:solid_cable_messages, :channel_hash)
      add_index :solid_cable_messages, :channel_hash, name: :index_solid_cable_messages_on_channel_hash
    end
    
    unless index_exists?(:solid_cable_messages, :created_at)
      add_index :solid_cable_messages, :created_at, name: :index_solid_cable_messages_on_created_at
    end
  end
end 