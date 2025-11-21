# frozen_string_literal: true
# shareable_constant_value: literal

class UpdateTimestampsInAccountsRoles < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up do
        now = Time.current
        ts = now.strftime('%Y-%m-%d %H:%M:%S')
        execute "UPDATE accounts_roles SET created_at = '#{ts}', updated_at = '#{ts}' WHERE created_at IS NULL OR updated_at IS NULL"
        change_column_null :accounts_roles, :created_at, false
        change_column_null :accounts_roles, :updated_at, false
      end
    end
  end
end
