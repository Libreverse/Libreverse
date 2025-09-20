# frozen_string_literal: true

require "sequel"
require "sequel/extensions/activerecord_connection"

# Allow defining models before tables exist (test boot, schema load) without raising.
Sequel::Model.require_valid_table = false

# ActiveRecord uses the trilogy adapter in all environments; unify to avoid bridge mismatch.
adapter = :trilogy

# Use the same TiDB connection as ActiveRecord
DB = Sequel.connect(adapter: adapter, test: false, extensions: :activerecord_connection)
