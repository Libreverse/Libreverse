# frozen_string_literal: true

require "sequel"
require "sequel/extensions/activerecord_connection"

# Use the same SQLite connection as ActiveRecord
DB = Sequel.sqlite(extensions: :activerecord_connection)
