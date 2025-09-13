# frozen_string_literal: true

# Upgrade ActiveStorage DB service storage to LONGBLOB (~4GB) for MySQL/TiDB
class ChangeActiveStorageDBFilesDataToLongblob < ActiveRecord::Migration[8.0]
  def up
    return unless mysqlish?

    # LONGBLOB is selected by specifying a limit > 16MB
    change_column :active_storage_db_files, :data, :binary, limit: 4.gigabytes - 1
  end

  def down
    return unless mysqlish?

    # Revert to MEDIUMBLOB (16MB)
    change_column :active_storage_db_files, :data, :binary, limit: 16.megabytes
  end

  private

  def mysqlish?
    adapter = connection.adapter_name.to_s.downcase
    adapter.include?("mysql") || adapter.include?("trilogy")
  end
end
