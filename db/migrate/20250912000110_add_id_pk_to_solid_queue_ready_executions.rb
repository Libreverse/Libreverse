# frozen_string_literal: true

class AddIdPkToSolidQueueReadyExecutions < ActiveRecord::Migration[8.0]
  def up
    unless column_exists?(:solid_queue_ready_executions, :id)
      execute <<~SQL
        ALTER TABLE solid_queue_ready_executions
        ADD COLUMN id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST
      SQL
    end

    add_index :solid_queue_ready_executions, :job_id, unique: true, name: "index_solid_queue_ready_executions_on_job_id" unless index_exists?(:solid_queue_ready_executions, :job_id, unique: true, name: "index_solid_queue_ready_executions_on_job_id")

    add_index :solid_queue_ready_executions, %i[priority job_id], name: "index_solid_queue_poll_all" unless index_exists?(:solid_queue_ready_executions, %i[priority job_id], name: "index_solid_queue_poll_all")

    return if index_exists?(:solid_queue_ready_executions, %i[queue_name priority job_id], name: "index_solid_queue_poll_by_queue")

      add_index :solid_queue_ready_executions, %i[queue_name priority job_id], name: "index_solid_queue_poll_by_queue"
  end

  def down
    # No-op: don't drop id or performance-critical indexes.
  end
end
