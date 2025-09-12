# frozen_string_literal: true

class FixSolidQueueFailedExecutionsSchema < ActiveRecord::Migration[8.0]
  def up
    unless table_exists?(:solid_queue_failed_executions)
      create_table :solid_queue_failed_executions do |t|
        t.bigint :job_id, null: false
        t.text :error
        t.datetime :created_at, null: false

        t.index :job_id, unique: true, name: "index_solid_queue_failed_executions_on_job_id"
      end
      add_foreign_key :solid_queue_failed_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
      return
    end

    # If the table exists but doesn't have the expected columns, adjust it
    change_table :solid_queue_failed_executions do |t|
      t.bigint :job_id, null: false unless column_exists?(:solid_queue_failed_executions, :job_id)

      # Solid Queue stores a JSON-serialized error in a text column named :error
      t.text :error unless column_exists?(:solid_queue_failed_executions, :error)

      # Ensure created_at exists; drop updated_at if present to match expected schema
      t.datetime :created_at, null: false unless column_exists?(:solid_queue_failed_executions, :created_at)
    end

    remove_column :solid_queue_failed_executions, :updated_at if column_exists?(:solid_queue_failed_executions, :updated_at)

    # Add unique index on job_id
    add_index :solid_queue_failed_executions, :job_id, unique: true, name: "index_solid_queue_failed_executions_on_job_id" unless index_exists?(:solid_queue_failed_executions, :job_id, name: "index_solid_queue_failed_executions_on_job_id", unique: true)

    # Add FK to jobs table
    return if foreign_key_exists?(:solid_queue_failed_executions, :solid_queue_jobs)

      add_foreign_key :solid_queue_failed_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
  end

  def down
    # Non-destructive: we won't drop the table; only attempt to revert to a generic timestamps-only form if needed
    # For safety in production, leave as no-op
  end
end
