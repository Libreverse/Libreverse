class AddTimestampsToAccounts < ActiveRecord::Migration[8.0]
  def change
    # Add timestamps columns to accounts table
    change_table :accounts, bulk: true do |t|
      t.datetime :created_at, null: true
      t.datetime :updated_at, null: true
    end

    # Set default values for existing records
    # For created_at, use password_changed_at if available, otherwise current time
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE accounts#{' '}
          SET created_at = COALESCE(password_changed_at, NOW()),
              updated_at = NOW()
          WHERE created_at IS NULL;
        SQL
      end
    end

    # Make the columns not nullable after setting values
    change_table :accounts, bulk: true do |t|
      t.change_null :created_at, false
      t.change_null :updated_at, false
    end
  end
end
