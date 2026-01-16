# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class MigrateUserPreferencesDataToEncrypted < ActiveRecord::Migration[7.1]
  def up
    # Temporarily disable any callbacks or validations
    UserPreference.reset_callbacks(:save)
    UserPreference.reset_callbacks(:validate)

    # Migrate data in batches
    UserPreference.in_batches do |batch|
      batch.each do |pref|
        if pref.unencrypted_value.present?
          pref.value = pref.unencrypted_value
          pref.save!(validate: false)
        end
      end
    end

    # Remove the unencrypted column
    remove_column :user_preferences, :unencrypted_value
  end

  def down
    add_column :user_preferences, :unencrypted_value, :string

    # Temporarily disable any callbacks or validations
    UserPreference.reset_callbacks(:save)
    UserPreference.reset_callbacks(:validate)

    # Migrate data back in batches
    UserPreference.in_batches do |batch|
      batch.each do |pref|
        if pref.value.present?
          pref.unencrypted_value = pref.value
          pref.save!(validate: false)
        end
      end
    end

    rename_column :user_preferences, :value_ciphertext, :old_value_ciphertext
  end
end
