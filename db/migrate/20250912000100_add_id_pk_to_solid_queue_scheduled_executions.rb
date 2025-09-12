# frozen_string_literal: true

class AddIdPkToSolidQueueScheduledExecutions < ActiveRecord::Migration[8.0]
  def up
    # TiDB/MySQL: Some locking queries require a primary key/unique key.
    # Older Solid Queue setups may have created this table without an `id` PK.
    unless column_exists?(:solid_queue_scheduled_executions, :id)
      # Add an auto-incrementing bigint primary key column named `id`.
      # Using raw SQL to ensure correct attributes on TiDB/MySQL.
      execute <<~SQL
        ALTER TABLE solid_queue_scheduled_executions
        ADD COLUMN id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST
      SQL
    end

    # Ensure the unique key on job_id exists (required by Solid Queue).
    add_index :solid_queue_scheduled_executions, :job_id, unique: true, name: "index_solid_queue_scheduled_executions_on_job_id" unless index_exists?(:solid_queue_scheduled_executions, :job_id, unique: true, name: "index_solid_queue_scheduled_executions_on_job_id")

    # Ensure the covering dispatch index exists and is correctly named.
    return if index_exists?(:solid_queue_scheduled_executions, %i[scheduled_at priority job_id], name: "index_solid_queue_dispatch_all")

      add_index :solid_queue_scheduled_executions, %i[scheduled_at priority job_id], name: "index_solid_queue_dispatch_all"
  end

  def down
    # We intentionally do not drop the id PK to avoid breaking Solid Queue.
    # No-op on down.
  end
end
