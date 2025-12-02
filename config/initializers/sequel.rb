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
