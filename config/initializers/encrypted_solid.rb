# Apply Active Record Encryption to Solid Cable and Solid Queue data.
# Note: Solid Cache entries are now encrypted using Solid Cache's built-in encryption feature.
# This ensures ActionCable payloads and job data are stored encrypted at rest,
# mirroring the protection we added for Rodauth-related tables.

module EncryptionHelper
  def self.column?(model_class, column_name)
    return false unless model_class.respond_to?(:table_exists?)

    # Check if database exists before checking table existence
    begin
      # SQLite3Adapter doesn't have current_database method
      model_class.connection.current_database unless model_class.connection.is_a?(ActiveRecord::ConnectionAdapters::SQLite3Adapter)
    rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
      return false
    end

    return false unless model_class.table_exists?

    begin
      model_class.columns_hash.key?(column_name.to_s)
    rescue ActiveRecord::StatementInvalid
      false
    end
  end
end

Rails.application.config.to_prepare do
  # Note: SolidCache::Entry encryption is now handled by Solid Cache's built-in encryption feature
  # enabled in config/cache.yml with encrypt: true

  # Encrypt SolidCable messages (payload column contains serialized data)
  if defined?(SolidCable::Message) && EncryptionHelper.column?(SolidCable::Message, :payload)
    SolidCable::Message.class_eval do
      encrypts :payload
    end
  end

  # Encrypt SolidQueue job arguments and concurrency keys
  if defined?(SolidQueue::Job)
    SolidQueue::Job.class_eval do
      encrypts :arguments if EncryptionHelper.column?(self, :arguments)
      encrypts :concurrency_key if EncryptionHelper.column?(self, :concurrency_key)
    end
  end

  # Encrypt concurrency_key on blocked executions if present
  if defined?(SolidQueue::BlockedExecution)
    SolidQueue::BlockedExecution.class_eval do
      encrypts :concurrency_key if EncryptionHelper.column?(self, :concurrency_key)
    end
  end

  # Encrypt process metadata
  if defined?(SolidQueue::Process)
    SolidQueue::Process.class_eval do
      encrypts :metadata if EncryptionHelper.column?(self, :metadata)
    end
  end

  # Encrypt SolidQueue recurring task arguments
  if defined?(SolidQueue::RecurringTask)
    SolidQueue::RecurringTask.class_eval do
      encrypts :arguments if EncryptionHelper.column?(self, :arguments)
    end
  end

  # Encrypt ActiveRecord session store data if present
  if Object.const_defined?(:Session)
    Session.class_eval do
      encrypts :data if EncryptionHelper.column?(self, :data)
    end
  end
end
