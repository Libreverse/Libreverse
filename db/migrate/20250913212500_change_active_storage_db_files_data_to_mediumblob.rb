# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

# Ensure ActiveStorage DB service can store files larger than 64KB on MySQL/TiDB
# By default, `t.binary` maps to BLOB (64KB). We upgrade to MEDIUMBLOB (16MB).
class ChangeActiveStorageDBFilesDataToMediumblob < ActiveRecord::Migration[8.0]
  def up
    return unless mysqlish?

    # MEDIUMBLOB max size is 16MB, which fits most uploads while keeping storage reasonable.
    change_column :active_storage_db_files, :data, :binary, limit: 16.megabytes
  end

  def down
    return unless mysqlish?

    # Revert back to default BLOB (64KB)
    change_column :active_storage_db_files, :data, :binary
  end

  private

  def mysqlish?
    adapter = connection.adapter_name.to_s.downcase
    adapter.include?("mysql") || adapter.include?("trilogy")
  end
end
