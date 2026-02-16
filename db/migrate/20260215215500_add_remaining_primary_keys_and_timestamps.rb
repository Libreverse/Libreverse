# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class AddRemainingPrimaryKeysAndTimestamps < ActiveRecord::Migration[8.1]
  def up
    add_ts(:solid_cable_messages, :updated_at)
    add_ts(:solid_cache_entries, :updated_at)
    add_ts(:solid_queue_blocked_executions, :updated_at)
    add_ts(:solid_queue_claimed_executions, :updated_at)
    add_ts(:solid_queue_failed_executions, :updated_at)
    add_ts(:solid_queue_pauses, :updated_at)
    add_ts(:solid_queue_processes, :updated_at)
    add_ts(:solid_queue_ready_executions, :updated_at)
    add_ts(:solid_queue_recurring_executions, :updated_at)
    add_ts(:solid_queue_scheduled_executions, :updated_at)

    add_ts(:test, :created_at)
    add_ts(:test, :updated_at)

    change_column_null(:test, :id, false) if table_exists?(:test) && column_exists?(:test, :id)

    add_pk(:account_active_session_keys, %w[session_id])
    add_pk(:accounts_roles, %w[account_id role_id])
    add_pk(:comment_hierarchies, %w[ancestor_id descendant_id generations])
    add_pk(:test, %w[id])
  end

  def down
    remove_pk(:test)
    remove_pk(:comment_hierarchies)
    remove_pk(:accounts_roles)
    remove_pk(:account_active_session_keys)

    remove_ts(:test, :created_at)
    remove_ts(:test, :updated_at)

    remove_ts(:solid_cable_messages, :updated_at)
    remove_ts(:solid_cache_entries, :updated_at)
    remove_ts(:solid_queue_blocked_executions, :updated_at)
    remove_ts(:solid_queue_claimed_executions, :updated_at)
    remove_ts(:solid_queue_failed_executions, :updated_at)
    remove_ts(:solid_queue_pauses, :updated_at)
    remove_ts(:solid_queue_processes, :updated_at)
    remove_ts(:solid_queue_ready_executions, :updated_at)
    remove_ts(:solid_queue_recurring_executions, :updated_at)
    remove_ts(:solid_queue_scheduled_executions, :updated_at)
  end

  private

  def add_ts(table, column)
    return unless table_exists?(table)
    return if column_exists?(table, column)

    add_column table, column, :datetime
    now = Time.current
    execute <<~SQL.squish
      UPDATE #{quote_table_name(table)}
      SET #{quote_column_name(column)} = #{connection.quote(now)}
      WHERE #{quote_column_name(column)} IS NULL
    SQL
    change_column_null table, column, false
  end

  def remove_ts(table, column)
    return unless table_exists?(table)
    return unless column_exists?(table, column)

    remove_column table, column
  end

  def add_pk(table, columns)
    return unless table_exists?(table)
    return if connection.primary_key(table).present?

    quoted_columns = columns.map { |column| quote_column_name(column) }.join(", ")
    execute "ALTER TABLE #{quote_table_name(table)} ADD PRIMARY KEY (#{quoted_columns})"
  end

  def remove_pk(table)
    return unless table_exists?(table)
    return if connection.primary_key(table).nil?

    execute "ALTER TABLE #{quote_table_name(table)} DROP PRIMARY KEY"
  end
end
