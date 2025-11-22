# frozen_string_literal: true
# shareable_constant_value: literal

# Apply Active Record Encryption to Solid Cable data.
# Note: Solid Cache entries are now encrypted using Solid Cache's built-in encryption feature.
# This ensures ActionCable payloads are stored encrypted at rest,
# mirroring the protection we added for Rodauth-related tables.

module EncryptionHelper
  def self.column?(model_class, column_name)
    return false unless model_class.respond_to?(:table_exists?)

    # Check if database exists before checking table existence
    begin
      model_class.connection.current_database
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
  # NOTE: SolidCache::Entry encryption is now handled by Solid Cache's built-in encryption feature
  # enabled in config/cache.yml with encrypt: true

  # Encrypt SolidCable messages (payload column contains serialized data)
  if defined?(SolidCable::Message) && EncryptionHelper.column?(SolidCable::Message, :payload)
    SolidCable::Message.class_eval do
      encrypts :payload
    end
  end

  # Encrypt ActiveRecord session store data if present
  if Object.const_defined?(:Session)
    Session.class_eval do
      encrypts :data if EncryptionHelper.column?(self, :data)
    end
  end
end
