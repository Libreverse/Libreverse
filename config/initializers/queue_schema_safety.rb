# frozen_string_literal: true
# shareable_constant_value: literal

# Test/schema load safety shim: avoid FK constraint errors when loading db/queue_schema.rb
# without modifying the auto-generated queue_schema file itself.
#
# Problem: queue_schema.rb (for the queue database) currently contains a full copy of core tables
# (accounts, experiences, etc.). When Rails loads schemas for multiple databases, it attempts to
# drop and recreate those tables with force: :cascade. MySQL/TiDB refuses to drop a parent table
# referenced by foreign keys from still-present child tables, causing test boot to abort.
#
# Approach: During the loading of db/queue_schema.rb only, intercept create_table calls targeting
# known core tables that already exist and strip the :force option so we do NOT drop them. This
# is minimally invasive, does not alter generated schema files, and is test-safe.
#
# The patch is scoped by inspecting the Ruby call stack for 'db/queue_schema.rb'. If that file is
# not on the stack we fall through to the normal create_table behavior.
#
# NOTE: Keep the duplicate table list conservative; adding a table here simply prevents an
# unnecessary drop/recreate cycle if it already exists.

if Rails.env.test?
  module QueueSchemaSafety
    DUPLICATE_TABLES = %w[
      accounts
      experiences
      experience_vectors
      user_preferences
      accounts_roles
      account_active_session_keys
      account_login_change_keys
      account_password_reset_keys
      account_remember_keys
      account_session_keys
      account_verification_keys
      roles
      active_storage_blobs
      active_storage_attachments
      active_storage_variant_records
    ].freeze

    def create_table(table_name, **options, &block)
      if queue_schema_load_in_progress? && DUPLICATE_TABLES.include?(table_name.to_s)
        if data_source_exists?(table_name)
          Rails.logger.info "[queue_schema_safety] Skipping duplicate table '#{table_name}' creation during queue_schema load" if defined?(Rails.logger)
          return true # pretend success
        end
        # Table not present: allow creation but remove force to avoid unintended cascades
        if options[:force]
          filtered = options.dup
          filtered.delete(:force)
          return super(table_name, **filtered, &block)
        end
      end
      super
    end

    private

    def queue_schema_load_in_progress?
      # Stack inspection; cheap and localized to schema load phase.
      caller.any? { |l| l.include?("db/queue_schema.rb") }
    end
  end

  ActiveSupport.on_load(:active_record) do
    adapter_class = ActiveRecord::Base.connection.class
    adapter_class.prepend(QueueSchemaSafety) unless adapter_class < QueueSchemaSafety
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished
    # Connection may not be established yet; patch after connect
    ActiveSupport::Notifications.subscribe("!queue_schema_safety.post_connect") do
        adapter_class = ActiveRecord::Base.connection.class
        adapter_class.prepend(QueueSchemaSafety) unless adapter_class < QueueSchemaSafety
    rescue StandardError
      # swallow; test boot will raise real errors if still broken
    end
  end
end
