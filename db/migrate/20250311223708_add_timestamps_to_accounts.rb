class AddTimestampsToAccounts < ActiveRecord::Migration[8.0]
  def change
    # Timestamps already exist, just update values for any null entries
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE accounts#{' '}
          SET created_at = CASE WHEN password_changed_at IS NOT NULL THEN password_changed_at ELSE NOW() END,
              updated_at = NOW()
          WHERE created_at IS NULL;
        SQL
      end
    end

    # Ensure columns are not nullable
    change_column_null :accounts, :created_at, false
    change_column_null :accounts, :updated_at, false
  end
end
