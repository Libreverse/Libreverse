# frozen_string_literal: true
# shareable_constant_value: literal

class AddTimestampsToAccountsRoles < ActiveRecord::Migration[7.0]
  def up
    # Add timestamps without defaults first, then update them
    add_column :accounts_roles, :created_at, :datetime
    add_column :accounts_roles, :updated_at, :datetime

    # Set current timestamp for existing records
    now = Time.current
    execute "UPDATE accounts_roles SET created_at = '#{now.strftime('%Y-%m-%d %H:%M:%S')}', updated_at = '#{now.strftime('%Y-%m-%d %H:%M:%S')}' WHERE created_at IS NULL OR updated_at IS NULL"

    # Now add the NOT NULL constraint
    change_column_null :accounts_roles, :created_at, false
    change_column_null :accounts_roles, :updated_at, false
  end

  def down
    remove_column :accounts_roles, :created_at
    remove_column :accounts_roles, :updated_at
  end
end
