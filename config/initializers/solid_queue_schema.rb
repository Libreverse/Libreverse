# frozen_string_literal: true

return unless defined?(SolidQueue::Job)

queue_conn = SolidQueue::Job.connection
unless queue_conn.data_source_exists?("solid_queue_jobs")
  schema_file = Rails.root.join("db/queue_schema.rb")

  if File.exist?(schema_file)
    Rails.logger.info("[Boot] Loading Solid Queue schema from #{schema_file}…")
    queue_conn.instance_eval(File.read(schema_file))
  else
    Rails.logger.warn("[Boot] queue_schema.rb not found – Solid Queue tables may be missing.")
  end
end
