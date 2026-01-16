# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

class FixAccountsPasswordHashConstraintForArgon2 < ActiveRecord::Migration[8.0]
  def up
    return unless table_exists?(:accounts)

      # Remove the old constraint if it exists
      begin
        remove_check_constraint :accounts, name: "accounts_password_hash_format"
      rescue StandardError => e
        say "Old accounts_password_hash_format constraint not present or already removed: #{e.message}"
      end

      # Update existing non-Argon2 password hashes to null (forcing password reset)
      non_argon2_count = connection.select_value("SELECT COUNT(*) FROM accounts WHERE password_hash IS NOT NULL AND password_hash NOT LIKE '$argon2%'")
      say "Found #{non_argon2_count} non-Argon2 password hashes that will be set to NULL (users will need to reset passwords)"
      execute("UPDATE accounts SET password_hash = NULL WHERE password_hash IS NOT NULL AND password_hash NOT LIKE '$argon2%'")
      say "Updated password hashes successfully"

      # Add the new Argon2-compatible constraint (allowing NULL values)
      add_check_constraint :accounts,
                           "(password_hash IS NULL OR password_hash LIKE '$argon2id$%' OR password_hash LIKE '$argon2i$%' OR password_hash LIKE '$argon2d$%')",
                           name: "accounts_password_hash_format"
  end

  def down
    return unless table_exists?(:accounts)

      remove_check_constraint :accounts, name: "accounts_password_hash_format"
      # Restore the old constraint (if needed) - also allowing NULL values
      add_check_constraint :accounts,
                           "(password_hash IS NULL OR password_hash LIKE 'AA__A%' OR password_hash LIKE 'Ag__A%' OR password_hash LIKE 'AQ__A%')",
                           name: "accounts_password_hash_format"
  end
end
