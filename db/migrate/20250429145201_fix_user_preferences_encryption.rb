# frozen_string_literal: true

class FixUserPreferencesEncryption < ActiveRecord::Migration[7.1]
  def up
    # Re-add unencrypted_value column temporarily
    add_column :user_preferences, :unencrypted_value, :string

    # Copy any existing unencrypted values from old records
    execute <<-SQL
      UPDATE user_preferences#{' '}
      SET unencrypted_value = value_ciphertext#{' '}
      WHERE value_ciphertext IS NOT NULL
    SQL

    # Clear out any potentially corrupted encrypted data
    execute <<-SQL
      UPDATE user_preferences#{' '}
      SET value_ciphertext = NULL
    SQL

    # Now properly encrypt the data using the model
    UserPreference.reset_column_information
    UserPreference.find_each do |pref|
      if pref.unencrypted_value.present?
        # Use update instead of update_column to trigger encryption
        pref.update!(value: pref.unencrypted_value)
      end
    end

    # Remove the temporary column
    remove_column :user_preferences, :unencrypted_value
  end

  def down
    # This migration is one-way since it's fixing data
    raise ActiveRecord::IrreversibleMigration
  end
end
