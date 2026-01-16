# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

class AddPasswordChangedAtToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :password_changed_at, :datetime

    # Set default value for existing records
    reversible do |dir|
      dir.up do
        # Set password_changed_at to current time for existing accounts
        execute <<-SQL
          UPDATE accounts#{' '}
          SET password_changed_at = NOW()
          WHERE password_changed_at IS NULL;
        SQL
      end
    end
  end
end
