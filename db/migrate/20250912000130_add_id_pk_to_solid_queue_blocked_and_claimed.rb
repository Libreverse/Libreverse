# frozen_string_literal: true

class AddIdPkToSolidQueueBlockedAndClaimed < ActiveRecord::Migration[8.0]
  TABLES = %i[
    solid_queue_blocked_executions
    solid_queue_claimed_executions
  ].freeze

  def up
    TABLES.each do |table|
      next if column_exists?(table, :id)

      execute <<~SQL
        ALTER TABLE #{table}
        ADD COLUMN id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST
      SQL
    end
  end

  def down
    # No-op
  end
end
