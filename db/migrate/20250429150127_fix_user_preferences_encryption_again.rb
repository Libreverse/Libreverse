class FixUserPreferencesEncryptionAgain < ActiveRecord::Migration[7.1]
  def up
    # Find all UserPreference records
    UserPreference.unscoped.find_each do |pref|
      # Skip if already properly encrypted
      next if pref.value.is_a?(ActiveRecord::Encryption::EncryptedAttributeType)

      # Standardize the value format
      raw_value = case pref.value.to_s.downcase
      when 'true', 't', '1', 'yes'
                    't'
      when 'false', 'f', '0', 'no'
                    'f'
      when 'dismissed'
                    't' # Convert dismissed to 't' since it represents a true state
      else
                    pref.value # Keep other values as is
      end

      # Re-save with standardized value to trigger encryption
      pref.value = raw_value
      pref.save(validate: false)
    end
  end

  def down
    # No rollback needed since we're just fixing encryption and standardizing values
    # The data should remain encrypted
  end
end
