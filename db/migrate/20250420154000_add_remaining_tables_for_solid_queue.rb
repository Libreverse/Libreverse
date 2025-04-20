# frozen_string_literal: true

class AddRemainingTablesForSolidQueue < ActiveRecord::Migration[8.0]
  def change
    # Only add the tables if they do not already exist to keep the migration idempotent

    unless table_exists?(:solid_queue_ready_executions)
      create_table :solid_queue_ready_executions do |t|
        t.bigint   :job_id,     null: false
        t.string   :queue_name, null: false
        t.integer  :priority,   default: 0, null: false
        t.datetime :created_at, null: false

        t.index :job_id, unique: true
        t.index %i[priority job_id], name: "index_solid_queue_poll_all"
        t.index %i[queue_name priority job_id], name: "index_solid_queue_poll_by_queue"
      end

      add_foreign_key :solid_queue_ready_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
    end

    unless table_exists?(:solid_queue_scheduled_executions)
      create_table :solid_queue_scheduled_executions do |t|
        t.bigint   :job_id,     null: false
        t.string   :queue_name, null: false
        t.integer  :priority,   default: 0, null: false
        t.datetime :scheduled_at, null: false
        t.datetime :created_at, null: false

        t.index :job_id, unique: true
        t.index %i[scheduled_at priority job_id], name: "index_solid_queue_dispatch_all"
      end

      add_foreign_key :solid_queue_scheduled_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
    end

    unless table_exists?(:solid_queue_processes)
      create_table :solid_queue_processes do |t|
        t.string   :kind,             null: false
        t.datetime :last_heartbeat_at, null: false
        t.bigint   :supervisor_id
        t.integer  :pid,              null: false
        t.string   :hostname
        t.text     :metadata
        t.datetime :created_at,       null: false
        t.string   :name,             null: false

        t.index :last_heartbeat_at
        t.index %i[name supervisor_id], unique: true
        t.index :supervisor_id
      end
    end

    unless table_exists?(:solid_queue_pauses)
      create_table :solid_queue_pauses do |t|
        t.string   :queue_name, null: false
        t.datetime :created_at, null: false

        t.index :queue_name, unique: true
      end
    end

    unless table_exists?(:solid_queue_semaphores)
      create_table :solid_queue_semaphores do |t|
        t.string   :key,       null: false
        t.integer  :value,     default: 1, null: false
        t.datetime :expires_at, null: false
        t.datetime :created_at, null: false
        t.datetime :updated_at, null: false

        t.index :expires_at
        t.index %i[key value]
        t.index :key, unique: true
      end
    end
  end
end 