# frozen_string_literal: true
# shareable_constant_value: literal

require "sequel"
require "sequel/extensions/activerecord_connection"

# Allow defining models before tables exist (test boot, schema load) without raising.
Sequel::Model.require_valid_table = false

# ActiveRecord uses the trilogy adapter in all environments; unify to avoid bridge mismatch.
adapter = :trilogy

# Use the same TiDB connection as ActiveRecord
Sequel.connect(adapter: adapter, test: false, extensions: :activerecord_connection)

# Disable SQL logging for Sequel
require "logger"
Sequel::DATABASES.first.logger = Logger.new("/dev/null")

# Silence Sequel SQL logs in ActiveRecord
ActiveSupport::Notifications.unsubscribe("sql.active_record")

require "active_support/key_generator"

# Derive a 32-byte key from Rails.application.secret_key_base
SEQUEL_COLUMN_ENCRYPTION_KEY = ActiveSupport::KeyGenerator.new(
  Rails.application.secret_key_base, iterations: 1000
).generate_key("sequel_column_encryption", 32).freeze

raise "Derived key must be 32 bytes" unless SEQUEL_COLUMN_ENCRYPTION_KEY.bytesize == 32
