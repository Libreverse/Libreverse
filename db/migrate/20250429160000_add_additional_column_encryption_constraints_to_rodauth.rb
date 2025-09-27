class AddAdditionalColumnEncryptionConstraintsToRodauth < ActiveRecord::Migration[8.0]
  ENCRYPTED_PATTERN = "(key LIKE 'AA__A%' OR key LIKE 'Ag__A%' OR key LIKE 'AQ__A%')".freeze
  ENCRYPTED_PATTERN_LOGIN = "(login LIKE 'AA__A%' OR login LIKE 'Ag__A%' OR login LIKE 'AQ__A%')".freeze

  def up
    if table_exists?(:account_verification_keys)
      add_check_constraint :account_verification_keys,
                           ENCRYPTED_PATTERN,
                           name: 'account_verification_keys_key_format'
      add_check_constraint :account_verification_keys,
                           'LENGTH(key) >= 88',
                           name: 'account_verification_keys_key_length'
    end

    return unless table_exists?(:account_login_change_keys)

      add_check_constraint :account_login_change_keys,
                           ENCRYPTED_PATTERN,
                           name: 'account_login_change_keys_key_format'
      add_check_constraint :account_login_change_keys,
                           'LENGTH(key) >= 88',
                           name: 'account_login_change_keys_key_length'

      add_check_constraint :account_login_change_keys,
                           ENCRYPTED_PATTERN_LOGIN,
                           name: 'account_login_change_keys_login_format'
      add_check_constraint :account_login_change_keys,
                           'LENGTH(login) >= 88',
                           name: 'account_login_change_keys_login_length'
  end

  def down
    if table_exists?(:account_verification_keys)
      remove_check_constraint :account_verification_keys, name: 'account_verification_keys_key_format'
      remove_check_constraint :account_verification_keys, name: 'account_verification_keys_key_length'
    end

    return unless table_exists?(:account_login_change_keys)

      remove_check_constraint :account_login_change_keys, name: 'account_login_change_keys_key_format'
      remove_check_constraint :account_login_change_keys, name: 'account_login_change_keys_key_length'
      remove_check_constraint :account_login_change_keys, name: 'account_login_change_keys_login_format'
      remove_check_constraint :account_login_change_keys, name: 'account_login_change_keys_login_length'
  end
end
