# frozen_string_literal: true
# shareable_constant_value: literal

class AddMissingTablesForSolidQueue < ActiveRecord::Migration[8.0]
  def change
    create_table :solid_queue_jobs do |t|
      t.string :queue_name, null: false
      t.string :class_name, null: false
      t.text :arguments
      t.integer :priority, default: 0, null: false
      t.string :active_job_id
      t.datetime :scheduled_at
      t.datetime :finished_at
      t.string :concurrency_key
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index [ :active_job_id ], name: "index_solid_queue_jobs_on_active_job_id"
      t.index [ :class_name ], name: "index_solid_queue_jobs_on_class_name"
      t.index [ :finished_at ], name: "index_solid_queue_jobs_on_finished_at"
      t.index %i[queue_name finished_at], name: "index_solid_queue_jobs_for_filtering"
      t.index %i[scheduled_at finished_at], name: "index_solid_queue_jobs_for_alerting"
    end

    create_table :solid_queue_recurring_executions do |t|
      t.bigint :job_id, null: false
      t.string :task_key, null: false
      t.datetime :run_at, null: false
      t.datetime :created_at, null: false

      t.index [ :job_id ], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
      t.index %i[task_key run_at], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
    end

    create_table :solid_queue_recurring_tasks do |t|
      t.string :key, null: false
      t.string :schedule, null: false
      t.string :command, limit: 2048
      t.string :class_name
      t.text :arguments
      t.string :queue_name
      t.integer :priority, default: 0
      t.boolean :static, default: true, null: false
      t.text :description
      t.timestamps

      t.index [ :key ], name: "index_solid_queue_recurring_tasks_on_key", unique: true
      t.index [ :static ], name: "index_solid_queue_recurring_tasks_on_static"
    end

    add_foreign_key :solid_queue_recurring_executions, :solid_queue_jobs,
                    column: :job_id, on_delete: :cascade
  end
end
