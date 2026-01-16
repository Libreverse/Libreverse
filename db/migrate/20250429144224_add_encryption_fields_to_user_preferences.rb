# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class AddEncryptionFieldsToUserPreferences < ActiveRecord::Migration[7.1]
  def change
    # Rename existing value column to unencrypted_value
    rename_column :user_preferences, :value, :unencrypted_value

    # Add encrypted value column and its IV
    add_column :user_preferences, :value_ciphertext, :text
  end
end
