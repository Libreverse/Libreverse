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
      unless column_exists?(:solid_queue_failed_executions, :job_id)
        t.bigint :job_id, null: false
      end

      # Solid Queue stores a JSON-serialized error in a text column named :error
      unless column_exists?(:solid_queue_failed_executions, :error)
        t.text :error
      end

      # Ensure created_at exists; drop updated_at if present to match expected schema
      unless column_exists?(:solid_queue_failed_executions, :created_at)
        t.datetime :created_at, null: false
      end
    end

    if column_exists?(:solid_queue_failed_executions, :updated_at)
      remove_column :solid_queue_failed_executions, :updated_at
    end

    # Add unique index on job_id
    unless index_exists?(:solid_queue_failed_executions, :job_id, name: "index_solid_queue_failed_executions_on_job_id", unique: true)
      add_index :solid_queue_failed_executions, :job_id, unique: true, name: "index_solid_queue_failed_executions_on_job_id"
    end

    # Add FK to jobs table
    unless foreign_key_exists?(:solid_queue_failed_executions, :solid_queue_jobs)
      add_foreign_key :solid_queue_failed_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
    end
  end

  def down
    # Non-destructive: we won't drop the table; only attempt to revert to a generic timestamps-only form if needed
    # For safety in production, leave as no-op
  end
end
