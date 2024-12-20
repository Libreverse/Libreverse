class CreateSolidQueueTables < ActiveRecord::Migration[8.0]
  def change
    create_table :solid_queue_blocked_executions do |t|
      t.bigint   :job_id,          null: false
      t.string   :queue_name,      null: false
      t.integer  :priority,        default: 0, null: false
      t.string   :concurrency_key, null: false
      t.datetime :expires_at,      null: false
      t.datetime :created_at,      null: false

      t.index [ :concurrency_key, :priority, :job_id ], name: "index_solid_queue_blocked_executions_for_release"
      t.index [ :expires_at, :concurrency_key ], name: "index_solid_queue_blocked_executions_for_maintenance"
      t.index :job_id, unique: true
    end

    create_table :solid_queue_claimed_executions do |t|
      t.bigint   :job_id,     null: false
      t.bigint   :process_id
      t.datetime :created_at, null: false

      t.index :job_id, unique: true
      t.index [ :process_id, :job_id ], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
    end

    create_table :solid_queue_failed_executions do |t|
      # Define the columns as per your schema
    end
  end
end
