# frozen_string_literal: true
# shareable_constant_value: literal

class EnforceUniqueSessionIdOnSessionFinalizations < ActiveRecord::Migration[7.1]
  def up
    return unless table_exists?(:session_finalizations)

    if postgres?
      disable_ddl_transaction!
      add_index :session_finalizations, :session_id, unique: true, algorithm: :concurrently, if_not_exists: true
    else
      add_index :session_finalizations, :session_id, unique: true, if_not_exists: true
    end

    # Ensure NOT NULL at DB level
    return unless column_exists?(:session_finalizations, :session_id)

      change_column_null :session_finalizations, :session_id, false
  end

  def down
    return unless table_exists?(:session_finalizations)

    if postgres?
      disable_ddl_transaction!
      remove_index :session_finalizations, column: :session_id, algorithm: :concurrently, if_exists: true
    else
      remove_index :session_finalizations, column: :session_id, if_exists: true
    end

    # Allow NULL again (reverses the up); keep guard for safety
    return unless column_exists?(:session_finalizations, :session_id)

      change_column_null :session_finalizations, :session_id, true
  end

  private

  def postgres?
    ActiveRecord::Base.connection.adapter_name.downcase.include?("postgresql")
  end
end
