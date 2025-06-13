CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "solid_cache_entries" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "key" blob(1024) NOT NULL, "value" blob(536870912) NOT NULL, "created_at" datetime(6) NOT NULL, "key_hash" bigint NOT NULL, "byte_size" integer NOT NULL);
CREATE INDEX "index_solid_cache_entries_on_byte_size" ON "solid_cache_entries" ("byte_size");
CREATE INDEX "index_solid_cache_entries_on_key_hash_and_byte_size" ON "solid_cache_entries" ("key_hash", "byte_size");
CREATE UNIQUE INDEX "index_solid_cache_entries_on_key_hash" ON "solid_cache_entries" ("key_hash");
CREATE TABLE IF NOT EXISTS "solid_queue_blocked_executions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "job_id" bigint NOT NULL, "queue_name" varchar NOT NULL, "priority" integer DEFAULT 0 NOT NULL, "concurrency_key" varchar NOT NULL, "expires_at" datetime(6) NOT NULL, "created_at" datetime(6) NOT NULL);
CREATE INDEX "index_solid_queue_blocked_executions_for_release" ON "solid_queue_blocked_executions" ("concurrency_key", "priority", "job_id");
CREATE INDEX "index_solid_queue_blocked_executions_for_maintenance" ON "solid_queue_blocked_executions" ("expires_at", "concurrency_key");
CREATE UNIQUE INDEX "index_solid_queue_blocked_executions_on_job_id" ON "solid_queue_blocked_executions" ("job_id");
CREATE TABLE IF NOT EXISTS "solid_queue_claimed_executions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "job_id" bigint NOT NULL, "process_id" bigint, "created_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_solid_queue_claimed_executions_on_job_id" ON "solid_queue_claimed_executions" ("job_id");
CREATE INDEX "index_solid_queue_claimed_executions_on_process_id_and_job_id" ON "solid_queue_claimed_executions" ("process_id", "job_id");
CREATE TABLE IF NOT EXISTS "solid_queue_failed_executions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "account_password_reset_keys" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "key" varchar NOT NULL, "deadline" datetime(6) NOT NULL, "email_last_sent" datetime(6) DEFAULT CURRENT_TIMESTAMP NOT NULL, CONSTRAINT "fk_rails_ccaeb37cea"
FOREIGN KEY ("id")
  REFERENCES "accounts" ("id")
);
CREATE TABLE IF NOT EXISTS "account_remember_keys" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "key" varchar NOT NULL, "deadline" datetime(6) NOT NULL, CONSTRAINT "fk_rails_9b2f6d8501"
FOREIGN KEY ("id")
  REFERENCES "accounts" ("id")
);
CREATE TABLE IF NOT EXISTS "solid_queue_jobs" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "queue_name" varchar NOT NULL, "class_name" varchar NOT NULL, "arguments" text, "priority" integer DEFAULT 0 NOT NULL, "active_job_id" varchar, "scheduled_at" datetime(6), "finished_at" datetime(6), "concurrency_key" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE INDEX "index_solid_queue_jobs_on_active_job_id" ON "solid_queue_jobs" ("active_job_id");
CREATE INDEX "index_solid_queue_jobs_on_class_name" ON "solid_queue_jobs" ("class_name");
CREATE INDEX "index_solid_queue_jobs_on_finished_at" ON "solid_queue_jobs" ("finished_at");
CREATE INDEX "index_solid_queue_jobs_for_filtering" ON "solid_queue_jobs" ("queue_name", "finished_at");
CREATE INDEX "index_solid_queue_jobs_for_alerting" ON "solid_queue_jobs" ("scheduled_at", "finished_at");
CREATE TABLE IF NOT EXISTS "solid_queue_recurring_tasks" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "key" varchar NOT NULL, "schedule" varchar NOT NULL, "command" varchar(2048), "class_name" varchar, "arguments" text, "queue_name" varchar, "priority" integer DEFAULT 0, "static" boolean DEFAULT 1 NOT NULL, "description" text, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_solid_queue_recurring_tasks_on_key" ON "solid_queue_recurring_tasks" ("key");
CREATE INDEX "index_solid_queue_recurring_tasks_on_static" ON "solid_queue_recurring_tasks" ("static");
CREATE TABLE IF NOT EXISTS "solid_queue_recurring_executions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "job_id" bigint NOT NULL, "task_key" varchar NOT NULL, "run_at" datetime(6) NOT NULL, "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_318a5533ed"
FOREIGN KEY ("job_id")
  REFERENCES "solid_queue_jobs" ("id")
 ON DELETE CASCADE);
CREATE UNIQUE INDEX "index_solid_queue_recurring_executions_on_job_id" ON "solid_queue_recurring_executions" ("job_id");
CREATE UNIQUE INDEX "index_solid_queue_recurring_executions_on_task_key_and_run_at" ON "solid_queue_recurring_executions" ("task_key", "run_at");
CREATE TABLE IF NOT EXISTS "solid_cable_messages" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "channel" blob(1024) NOT NULL, "payload" blob(536870912) NOT NULL, "created_at" datetime(6) NOT NULL, "channel_hash" integer(8) NOT NULL);
CREATE INDEX "index_solid_cable_messages_on_channel" ON "solid_cable_messages" ("channel");
CREATE INDEX "index_solid_cable_messages_on_channel_hash" ON "solid_cable_messages" ("channel_hash");
CREATE INDEX "index_solid_cable_messages_on_created_at" ON "solid_cable_messages" ("created_at");
CREATE TABLE IF NOT EXISTS "active_storage_blobs" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "key" varchar NOT NULL, "filename" varchar NOT NULL, "content_type" varchar, "metadata" text, "service_name" varchar NOT NULL, "byte_size" bigint NOT NULL, "checksum" varchar, "created_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_active_storage_blobs_on_key" ON "active_storage_blobs" ("key");
CREATE TABLE IF NOT EXISTS "active_storage_attachments" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "record_type" varchar NOT NULL, "record_id" bigint NOT NULL, "blob_id" bigint NOT NULL, "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_c3b3935057"
FOREIGN KEY ("blob_id")
  REFERENCES "active_storage_blobs" ("id")
);
CREATE INDEX "index_active_storage_attachments_on_blob_id" ON "active_storage_attachments" ("blob_id");
CREATE UNIQUE INDEX "index_active_storage_attachments_uniqueness" ON "active_storage_attachments" ("record_type", "record_id", "name", "blob_id");
CREATE TABLE IF NOT EXISTS "active_storage_variant_records" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "blob_id" bigint NOT NULL, "variation_digest" varchar NOT NULL, CONSTRAINT "fk_rails_993965df05"
FOREIGN KEY ("blob_id")
  REFERENCES "active_storage_blobs" ("id")
);
CREATE UNIQUE INDEX "index_active_storage_variant_records_uniqueness" ON "active_storage_variant_records" ("blob_id", "variation_digest");
CREATE TABLE IF NOT EXISTS "experiences" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "title" varchar, "description" text, "author" varchar, "account_id" integer NOT NULL, "approved" boolean DEFAULT 0 NOT NULL, CONSTRAINT "fk_rails_3898738ded"
FOREIGN KEY ("account_id")
  REFERENCES "accounts" ("id")
);
CREATE INDEX "index_experiences_on_account_id" ON "experiences" ("account_id");
CREATE INDEX "index_experiences_on_account_id_and_created_at" ON "experiences" ("account_id", "created_at");
CREATE TABLE IF NOT EXISTS "solid_queue_ready_executions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "job_id" bigint NOT NULL, "queue_name" varchar NOT NULL, "priority" integer DEFAULT 0 NOT NULL, "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_81fcbd66af"
FOREIGN KEY ("job_id")
  REFERENCES "solid_queue_jobs" ("id")
 ON DELETE CASCADE);
CREATE UNIQUE INDEX "index_solid_queue_ready_executions_on_job_id" ON "solid_queue_ready_executions" ("job_id");
CREATE INDEX "index_solid_queue_poll_all" ON "solid_queue_ready_executions" ("priority", "job_id");
CREATE INDEX "index_solid_queue_poll_by_queue" ON "solid_queue_ready_executions" ("queue_name", "priority", "job_id");
CREATE TABLE IF NOT EXISTS "solid_queue_scheduled_executions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "job_id" bigint NOT NULL, "queue_name" varchar NOT NULL, "priority" integer DEFAULT 0 NOT NULL, "scheduled_at" datetime(6) NOT NULL, "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_c4316f352d"
FOREIGN KEY ("job_id")
  REFERENCES "solid_queue_jobs" ("id")
 ON DELETE CASCADE);
CREATE UNIQUE INDEX "index_solid_queue_scheduled_executions_on_job_id" ON "solid_queue_scheduled_executions" ("job_id");
CREATE INDEX "index_solid_queue_dispatch_all" ON "solid_queue_scheduled_executions" ("scheduled_at", "priority", "job_id");
CREATE TABLE IF NOT EXISTS "solid_queue_processes" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "kind" varchar NOT NULL, "last_heartbeat_at" datetime(6) NOT NULL, "supervisor_id" bigint, "pid" integer NOT NULL, "hostname" varchar, "metadata" text, "created_at" datetime(6) NOT NULL, "name" varchar NOT NULL);
CREATE INDEX "index_solid_queue_processes_on_last_heartbeat_at" ON "solid_queue_processes" ("last_heartbeat_at");
CREATE UNIQUE INDEX "index_solid_queue_processes_on_name_and_supervisor_id" ON "solid_queue_processes" ("name", "supervisor_id");
CREATE INDEX "index_solid_queue_processes_on_supervisor_id" ON "solid_queue_processes" ("supervisor_id");
CREATE TABLE IF NOT EXISTS "solid_queue_pauses" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "queue_name" varchar NOT NULL, "created_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_solid_queue_pauses_on_queue_name" ON "solid_queue_pauses" ("queue_name");
CREATE TABLE IF NOT EXISTS "solid_queue_semaphores" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "key" varchar NOT NULL, "value" integer DEFAULT 1 NOT NULL, "expires_at" datetime(6) NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE INDEX "index_solid_queue_semaphores_on_expires_at" ON "solid_queue_semaphores" ("expires_at");
CREATE INDEX "index_solid_queue_semaphores_on_key_and_value" ON "solid_queue_semaphores" ("key", "value");
CREATE UNIQUE INDEX "index_solid_queue_semaphores_on_key" ON "solid_queue_semaphores" ("key");
CREATE INDEX "index_experiences_on_approved" ON "experiences" ("approved");
CREATE TABLE IF NOT EXISTS "accounts" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "status" integer DEFAULT 1 NOT NULL, "username" text NOT NULL, "password_hash" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "password_changed_at" datetime(6), "guest" boolean DEFAULT 0, "admin" boolean DEFAULT 0 NOT NULL, CONSTRAINT accounts_password_hash_format CHECK ((password_hash IS NULL OR password_hash LIKE '$argon2id$%' OR password_hash LIKE '$argon2i$%' OR password_hash LIKE '$argon2d$%')));
CREATE UNIQUE INDEX "index_accounts_on_username" ON "accounts" ("username");
CREATE INDEX "index_accounts_on_admin" ON "accounts" ("admin");
CREATE TABLE IF NOT EXISTS "user_preferences" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "account_id" integer NOT NULL, "key" varchar NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "value" varchar, "value_ciphertext" text, CONSTRAINT "fk_rails_d3b54c2dba"
FOREIGN KEY ("account_id")
  REFERENCES "accounts" ("id")
);
CREATE INDEX "index_user_preferences_on_account_id" ON "user_preferences" ("account_id");
CREATE UNIQUE INDEX "index_user_preferences_on_account_id_and_key" ON "user_preferences" ("account_id", "key");
CREATE TABLE IF NOT EXISTS "account_verification_keys" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "key" varchar NOT NULL, "requested_at" datetime(6) DEFAULT CURRENT_TIMESTAMP NOT NULL, "email_last_sent" datetime(6) DEFAULT CURRENT_TIMESTAMP NOT NULL, CONSTRAINT "fk_rails_2e3b612008"
FOREIGN KEY ("id")
  REFERENCES "accounts" ("id")
, CONSTRAINT account_verification_keys_key_format CHECK ((key LIKE 'AA__A%' OR key LIKE 'Ag__A%' OR key LIKE 'AQ__A%')), CONSTRAINT account_verification_keys_key_length CHECK (LENGTH(key) >= 88));
CREATE TABLE IF NOT EXISTS "account_login_change_keys" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "key" varchar NOT NULL, "login" varchar NOT NULL, "deadline" datetime(6) NOT NULL, CONSTRAINT "fk_rails_18962144a4"
FOREIGN KEY ("id")
  REFERENCES "accounts" ("id")
, CONSTRAINT account_login_change_keys_key_format CHECK ((key LIKE 'AA__A%' OR key LIKE 'Ag__A%' OR key LIKE 'AQ__A%')), CONSTRAINT account_login_change_keys_key_length CHECK (LENGTH(key) >= 88), CONSTRAINT account_login_change_keys_login_format CHECK ((login LIKE 'AA__A%' OR login LIKE 'Ag__A%' OR login LIKE 'AQ__A%')), CONSTRAINT account_login_change_keys_login_length CHECK (LENGTH(login) >= 88));
CREATE TABLE IF NOT EXISTS "moderation_logs" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "field" varchar, "model_type" varchar, "content" text, "reason" varchar, "account_id" integer, "violations_data" text, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_846bca589a"
FOREIGN KEY ("account_id")
  REFERENCES "accounts" ("id")
);
CREATE INDEX "index_moderation_logs_on_account_id" ON "moderation_logs" ("account_id");
CREATE TABLE IF NOT EXISTS "instance_settings" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "key" varchar NOT NULL, "value" text, "description" text, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_instance_settings_on_key" ON "instance_settings" ("key");
CREATE TABLE IF NOT EXISTS "experience_vectors" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "experience_id" integer NOT NULL, "vector_data" text NOT NULL, "vector_hash" varchar NOT NULL, "generated_at" datetime(6) NOT NULL, "version" integer DEFAULT 1 NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_d6a6d7b366"
FOREIGN KEY ("experience_id")
  REFERENCES "experiences" ("id")
);
CREATE UNIQUE INDEX "index_experience_vectors_on_experience_id" ON "experience_vectors" ("experience_id");
CREATE INDEX "index_experience_vectors_on_vector_hash" ON "experience_vectors" ("vector_hash");
CREATE INDEX "index_experience_vectors_on_generated_at" ON "experience_vectors" ("generated_at");
INSERT INTO "schema_migrations" (version) VALUES
('20250611142704'),
('20250528175828'),
('20250525235723'),
('20250429160000'),
('20250429153606'),
('20250429150127'),
('20250429145201'),
('20250429144245'),
('20250429144224'),
('20250427194000'),
('20250421231000'),
('20250420154000'),
('20250420003000'),
('20250412165601'),
('20250412120542'),
('20250405190936'),
('20250405190931'),
('20250328202000'),
('20250328010000'),
('20250328000000'),
('20250322095911'),
('20250319000000'),
('20250311223708'),
('20250311221942'),
('20250307195147'),
('20241219205719'),
('20241219205559'),
('20241219005940'),
('20241215205232'),
('20241025005517'),
('20240428153817');

