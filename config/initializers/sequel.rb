# frozen_string_literal: true

require "sequel"
require "sequel/extensions/activerecord_connection"

adapter = Rails.env.test? ? :mysql2 : :trilogy

# Use the same TiDB connection as ActiveRecord
DB = Sequel.connect(adapter: adapter, test: false, extensions: :activerecord_connection)
