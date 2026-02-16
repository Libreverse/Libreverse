# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class AddMissingForeignKeysPart1 < ActiveRecord::Migration[8.1]
  def change
    add_fk(:comments, :accounts, column: :account_id)
    add_fk(:comments, :comments, column: :parent_id)

    add_fk(:audits1984_audits, :console1984_users, column: :auditor_id)
    add_fk(:audits1984_audits, :console1984_sessions, column: :session_id)

    add_fk(:console1984_commands, :console1984_sessions, column: :session_id)
    add_fk(:console1984_commands, :console1984_sensitive_accesses, column: :sensitive_access_id)
    add_fk(:console1984_sensitive_accesses, :console1984_sessions, column: :session_id)
    add_fk(:console1984_sessions, :console1984_users, column: :user_id)
  end

  private

  def add_fk(from_table, to_table, column:)
    return unless column_exists?(from_table, column)
    return if foreign_key_exists?(from_table, to_table, column: column)

    add_foreign_key(from_table, to_table, column: column)
  end
end
