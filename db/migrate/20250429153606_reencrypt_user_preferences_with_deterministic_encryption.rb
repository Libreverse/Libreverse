# frozen_string_literal: true
# shareable_constant_value: literal

class ReencryptUserPreferencesWithDeterministicEncryption < ActiveRecord::Migration[7.1]
  def up
    # Add a temporary column to store the decrypted values
    add_column :user_preferences, :temp_value, :string

    # Copy decrypted values to temporary column
    UserPreference.unscoped.find_each do |pref|
      pref.temp_value = pref.value if pref.value.present?
      pref.save!(validate: false)
    end

    # Remove the encrypted column and rename temp column
    remove_column :user_preferences, :value_ciphertext
    rename_column :user_preferences, :temp_value, :value

    # Add back the encrypted column
    add_column :user_preferences, :value_ciphertext, :text

    # Re-encrypt all values with deterministic encryption
    UserPreference.unscoped.find_each do |pref|
      if pref.value.present?
        # Normalize the value before re-encrypting
        raw_value = case pref.value.to_s.downcase
        when "true", "t", "1", "yes", "dismissed"
                     "t"
        when "false", "f", "0", "no"
                     "f"
        else
                     pref.value
        end

        pref.value = raw_value
        pref.save!(validate: false)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
