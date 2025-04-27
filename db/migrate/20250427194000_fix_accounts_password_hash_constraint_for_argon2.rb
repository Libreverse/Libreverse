# frozen_string_literal: true

class FixAccountsPasswordHashConstraintForArgon2 < ActiveRecord::Migration[8.0]
  def up
    return unless table_exists?(:accounts)

      # Remove the old constraint if it exists
      begin
        remove_check_constraint :accounts, name: "accounts_password_hash_format"
      rescue StandardError => e
        say "Old accounts_password_hash_format constraint not present or already removed: #{e.message}"
      end
      # Add the new Argon2-compatible constraint
      add_check_constraint :accounts,
                           "(password_hash LIKE '$argon2id$%' OR password_hash LIKE '$argon2i$%' OR password_hash LIKE '$argon2d$%')",
                           name: "accounts_password_hash_format"
  end

  def down
    return unless table_exists?(:accounts)

      remove_check_constraint :accounts, name: "accounts_password_hash_format"
      # Restore the old constraint (if needed)
      add_check_constraint :accounts,
                           "(password_hash LIKE 'AA__A%' OR password_hash LIKE 'Ag__A%' OR password_hash LIKE 'AQ__A%')",
                           name: "accounts_password_hash_format"
  end
end
