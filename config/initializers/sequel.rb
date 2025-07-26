# frozen_string_literal: true

require "sequel"
require "sequel/extensions/activerecord_connection"

# Use the same TiDB connection as ActiveRecord
DB = Sequel.connect(adapter: :trilogy, test: false, extensions: :activerecord_connection)
