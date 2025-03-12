class AddTimestampsToAccounts < ActiveRecord::Migration[8.0]
  def change
    # Add timestamps columns to accounts table
    add_column :accounts, :created_at, :datetime, null: true
    add_column :accounts, :updated_at, :datetime, null: true

    # Set default values for existing records
    # For created_at, use password_changed_at if available, otherwise current time
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE accounts 
          SET created_at = COALESCE(password_changed_at, NOW()),
              updated_at = NOW()
          WHERE created_at IS NULL;
        SQL
      end
    end

    # Make the columns not nullable after setting values
    change_column_null :accounts, :created_at, false
    change_column_null :accounts, :updated_at, false
  end
end
