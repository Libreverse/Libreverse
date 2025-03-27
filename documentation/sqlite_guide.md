# SQLite Configuration Guide for Libreverse

This guide outlines the SQLite configuration used in Libreverse with the ActiveRecord enhanced SQLite adapter.

## Overview

Libreverse uses SQLite with the enhanced adapter for better feature support. The key advantages include:

1. Simple file-based database that requires no server
2. Enhanced SQLite features through the `activerecord-enhancedsqlite3-adapter` gem
3. Optimized configuration for ACID compliance and performance
4. Built-in support for JSON, full-text search, and other advanced features

## Required Gems

The SQLite setup requires these gems in your Gemfile:

```ruby
# Use SQLite as the database for Active Record with enhanced adapter
gem "activerecord-enhancedsqlite3-adapter", "~> 0.8.0"
gem "sqlite3", "~> 1.7.3"
```

Run bundle install to install these gems:

```bash
bundle install
```

## Database Configuration

The SQLite configuration in `config/database.yml` is set up with optimized settings:

```yaml
default: &default
  adapter: sqlite3
  pool: 10
  timeout: 5000
  pragmas:
    foreign_keys: 1
    trusted_schema: 0
    journal_mode: wal
    synchronous: FULL
    temp_store: MEMORY
    cache_size: 5000
    auto_vacuum: incremental
    locking_mode: NORMAL

development:
  <<: *default
  database: db/libreverse_development.sqlite3

test:
  <<: *default
  database: db/libreverse_test.sqlite3

production:
  <<: *default
  database: db/libreverse_production.sqlite3
```

## SQLite Configuration and Performance

The SQLite configuration has been carefully optimized to ensure ACID (Atomicity, Consistency, Isolation, Durability) compliance while maintaining good performance.

### ACID Compliance Settings

- **`foreign_keys = ON`**: Enforces referential integrity constraints
- **`trusted_schema = OFF`**: Enhances security by preventing potentially malicious SQLite extensions
- **`journal_mode = WAL`**: Uses Write-Ahead Logging to improve concurrency without sacrificing data integrity
- **`synchronous = FULL`**: Ensures maximum durability by waiting for data to be fully written to disk

### Performance Settings

- **`temp_store = MEMORY`**: Stores temporary tables in memory for faster operations
- **`cache_size = 5000`**: Increases cache size for better performance
- **`auto_vacuum = INCREMENTAL`**: Performs vacuuming incrementally to prevent database bloat

These settings are configured in `config/database.yml` and automatically applied by the enhanced SQLite adapter when the database connection is established.

## SQLite Feature Guide

SQLite differs from other databases like PostgreSQL in several ways. Here are some common patterns to use with SQLite:

### Working with Arrays

SQLite doesn't have native array support. Use these approaches instead:

```ruby
# In your models
serialize :tags, JSON

# In your SQL queries
# Instead of array operators, use JSON extraction:
# WHERE json_extract(tags, '$[0]') = 'ruby' OR json_extract(tags, '$[1]') = 'ruby'
```

### Case-Insensitive Text

For case-insensitive operations, use SQL LOWER functions:

```ruby
# In your queries
User.where("LOWER(username) = LOWER(?)", username)

# In your validations
validates :username, uniqueness: { case_sensitive: false }
```

### JSON Operations

SQLite supports JSON extraction with a specific syntax:

```ruby
# Extract a value from a JSON field
Document.where("json_extract(data, '$.status') = ?", 'active')

# Check if a JSON key exists
Document.where("json_extract(data, '$.status') IS NOT NULL")
```

## Common SQL Adjustments

Here are some common SQL adjustments to make when using SQLite:

1. **Date/Time functions**:
   ```ruby
   # Instead of NOW()
   # Use: datetime('now')
   ```

2. **Regular expressions**:
   ```ruby
   # Instead of: WHERE name ~ '^A'
   # Use: WHERE name REGEXP '^A'
   ```

3. **Full-text search**:
   With the FTS5 extension enabled, you can use full-text search:
   ```ruby
   # Create a virtual FTS table in a migration
   create_virtual_table :search_content, :fts5 do |t|
     t.string :title
     t.text :body
     t.options tokenize: 'porter'
   end
   
   # Search query
   SearchContent.where("search_content MATCH ?", 'query')
   ```

## Backup and Restore

One of SQLite's advantages is simple backup and restore:

```bash
# Backup: Simply copy the file
cp db/production.sqlite3 db/backups/production_backup_$(date +%Y%m%d).sqlite3

# Or use the SQLite .backup command
sqlite3 db/production.sqlite3 ".backup db/backups/production_backup.sqlite3"
```

## Performance Considerations

SQLite has different performance characteristics than client-server databases:

1. It's excellent for read-heavy applications but may be slower for write-heavy workloads
2. Only one process can write to the database at a time
3. WAL mode (enabled in our config) improves concurrency
4. For better performance with many concurrent users, consider adding a caching layer

## ActionCable with SQLite

Libreverse uses SolidCable, which stores channel data in the database rather than requiring Redis. With our SQLite configuration, ActionCable/SolidCable now stores its data in the same SQLite database.

The configuration in `config/cable.yml` looks like this:

```yaml
development:
  adapter: solid_cable
  connects_to:
    database:
      writing: primary
  polling_interval: "1.seconds"
  message_retention: "1.day"
  autotrim: true

test:
  adapter: test

production:
  adapter: solid_cable
  connects_to:
    database:
      writing: primary
  polling_interval: "1.seconds"
  message_retention: "1.day"
  autotrim: true
```

Note that SolidCable requires time durations to be specified as strings in the format "1.seconds" or "1.day". Using numeric values or other formats can cause parsing errors.

As a safety measure, we also include a small initializer to ensure the configuration values are always in the correct format:

```ruby
# config/initializers/solid_cable.rb
Rails.application.config.to_prepare do
  if defined?(SolidCable)
    # Set values that SolidCable can properly parse
    # SolidCable expects polling_interval and message_retention to be strings
    # in the format "1.seconds" or "1.day"
    if SolidCable.instance_variable_get(:@polling_interval).is_a?(Float)
      SolidCable.instance_variable_set(:@polling_interval, "1.seconds")
    end
    
    if SolidCable.instance_variable_get(:@message_retention).is_a?(Integer)
      SolidCable.instance_variable_set(:@message_retention, "1.day")
    end
    
    if !SolidCable.instance_variable_defined?(:@autotrim) || 
       SolidCable.instance_variable_get(:@autotrim).nil?
      SolidCable.instance_variable_set(:@autotrim, true)
    end
  end
end
```

This configuration uses the main SQLite database connection instead of requiring a separate database, simplifying deployment and maintenance.

### Required SolidCable Tables

SolidCable requires specific tables to store ActionCable messages. These tables are created by the migration:

```ruby
class CreateSolidCableTables < ActiveRecord::Migration[8.0]
  def change
    create_table "solid_cable_messages", force: :cascade do |t|
      t.binary "channel", limit: 1024, null: false
      t.binary "payload", limit: 536870912, null: false
      t.datetime "created_at", null: false
      t.integer "channel_hash", limit: 8, null: false
      t.index ["channel"], name: "index_solid_cable_messages_on_channel"
      t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
      t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
    end
  end
end
```

If you're setting up a new environment, make sure to run all migrations to create these tables:

```bash
rails db:migrate
```
