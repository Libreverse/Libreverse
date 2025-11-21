# frozen_string_literal: true
# shareable_constant_value: literal

class AddColumnEncryptionConstraintsToRodauth < ActiveRecord::Migration[8.0]
  def up
    # Remember Keys
    if table_exists?(:account_remember_keys)
      add_check_constraint :account_remember_keys,
                           "(key LIKE 'AA__A%' OR key LIKE 'Ag__A%' OR key LIKE 'AQ__A%')",
                           name: "account_remember_keys_key_format"
      add_check_constraint :account_remember_keys,
                           "LENGTH(key) >= 88",
                           name: "account_remember_keys_key_length"
    end

    # Password Reset Keys
    if table_exists?(:account_password_reset_keys)
      add_check_constraint :account_password_reset_keys,
                           "(key LIKE 'AA__A%' OR key LIKE 'Ag__A%' OR key LIKE 'AQ__A%')",
                           name: "account_password_reset_keys_key_format"
      add_check_constraint :account_password_reset_keys,
                           "LENGTH(key) >= 88",
                           name: "account_password_reset_keys_key_length"
    end

    # Accounts table (password_hash)
    return unless table_exists?(:accounts) && column_exists?(:accounts, :password_hash)

      add_check_constraint :accounts,
                           "(password_hash LIKE 'AA__A%' OR password_hash LIKE 'Ag__A%' OR password_hash LIKE 'AQ__A%')",
                           name: "accounts_password_hash_format"
      add_check_constraint :accounts,
                           "LENGTH(password_hash) >= 88",
                           name: "accounts_password_hash_length"
  end

  def down
    if table_exists?(:account_remember_keys)
      remove_check_constraint :account_remember_keys, name: "account_remember_keys_key_format"
      remove_check_constraint :account_remember_keys, name: "account_remember_keys_key_length"
    end
    if table_exists?(:account_password_reset_keys)
      remove_check_constraint :account_password_reset_keys, name: "account_password_reset_keys_key_format"
      remove_check_constraint :account_password_reset_keys, name: "account_password_reset_keys_key_length"
    end
    return unless table_exists?(:accounts)

      remove_check_constraint :accounts, name: "accounts_password_hash_format"
      remove_check_constraint :accounts, name: "accounts_password_hash_length"
  end
end
