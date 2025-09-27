class SetDefaultTimestampsForAccountActiveSessionKeys < ActiveRecord::Migration[7.0]
  def up
    execute "ALTER TABLE account_active_session_keys MODIFY created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP"
    execute "ALTER TABLE account_active_session_keys MODIFY last_use DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP"
  end

  def down
    execute "ALTER TABLE account_active_session_keys MODIFY created_at DATETIME NOT NULL"
    execute "ALTER TABLE account_active_session_keys MODIFY last_use DATETIME NOT NULL"
  end
end
