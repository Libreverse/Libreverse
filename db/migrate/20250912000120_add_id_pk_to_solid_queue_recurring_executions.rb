# frozen_string_literal: true
# shareable_constant_value: literal

class AddIdPkToSolidQueueRecurringExecutions < ActiveRecord::Migration[8.0]
  def up
    unless column_exists?(:solid_queue_recurring_executions, :id)
      execute <<~SQL
        ALTER TABLE solid_queue_recurring_executions
        ADD COLUMN id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST
      SQL
    end

    add_index :solid_queue_recurring_executions, :job_id, unique: true, name: "index_solid_queue_recurring_executions_on_job_id" unless index_exists?(:solid_queue_recurring_executions, :job_id, unique: true, name: "index_solid_queue_recurring_executions_on_job_id")

    return if index_exists?(:solid_queue_recurring_executions, %i[task_key run_at], unique: true, name: "index_solid_queue_recurring_executions_on_task_key_and_run_at")

      add_index :solid_queue_recurring_executions, %i[task_key run_at], unique: true, name: "index_solid_queue_recurring_executions_on_task_key_and_run_at"
  end

  def down
    # No-op: preserve PK and indexes.
  end
end
