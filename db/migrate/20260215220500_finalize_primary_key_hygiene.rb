# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class FinalizePrimaryKeyHygiene < ActiveRecord::Migration[8.1]
  def up
    remove_index :account_active_session_keys, name: :index_account_active_session_keys_on_session_id if index_exists?(:account_active_session_keys, name: :index_account_active_session_keys_on_session_id)

    change_column :test, :id, :bigint if table_exists?(:test) && column_exists?(:test, :id)

    add_surrogate_pk(:accounts_roles, %w[account_id role_id])
    add_surrogate_pk(:comment_hierarchies, %w[ancestor_id descendant_id generations])
  end

  def down
    drop_surrogate_pk(:comment_hierarchies)
    drop_surrogate_pk(:accounts_roles)

    change_column :test, :id, :integer if table_exists?(:test) && column_exists?(:test, :id)

    add_index :account_active_session_keys, :session_id, unique: true, name: :index_account_active_session_keys_on_session_id unless index_exists?(:account_active_session_keys, :session_id, name: :index_account_active_session_keys_on_session_id)
  end

  private

  def add_surrogate_pk(table, key_columns)
    return unless table_exists?(table)
    return if column_exists?(table, :id) && connection.primary_key(table).to_s == "id"

    execute "ALTER TABLE #{quote_table_name(table)} DROP PRIMARY KEY" if connection.primary_key(table).present?
    add_column(table, :id, :bigint) unless column_exists?(table, :id)

    join_on = key_columns.map { |column| "t.#{quote_column_name(column)} = src.#{quote_column_name(column)}" }.join(" AND ")
    order_by = key_columns.map { |column| quote_column_name(column) }.join(", ")
    projection = key_columns.map { |column| quote_column_name(column) }.join(", ")

    execute <<~SQL.squish
      UPDATE #{quote_table_name(table)} t
      JOIN (
        SELECT #{projection}, ROW_NUMBER() OVER (ORDER BY #{order_by}) AS rn
        FROM #{quote_table_name(table)}
      ) src ON #{join_on}
      SET t.id = src.rn
      WHERE t.id IS NULL
    SQL

    change_column_null(table, :id, false)
    execute "ALTER TABLE #{quote_table_name(table)} ADD PRIMARY KEY (id)"
  end

  def drop_surrogate_pk(table)
    return unless table_exists?(table)
    return unless column_exists?(table, :id)

    execute "ALTER TABLE #{quote_table_name(table)} DROP PRIMARY KEY"
    remove_column table, :id
  end
end
