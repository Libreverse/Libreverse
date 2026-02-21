# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class ReapplyMissingTimestampsPart1 < ActiveRecord::Migration[8.1]
  def up
    add_ts(:account_active_session_keys, :updated_at)

    add_ts(:account_login_change_keys, :created_at)
    add_ts(:account_login_change_keys, :updated_at)
    add_ts(:account_password_reset_keys, :created_at)
    add_ts(:account_password_reset_keys, :updated_at)
    add_ts(:account_remember_keys, :created_at)
    add_ts(:account_remember_keys, :updated_at)
    add_ts(:account_session_keys, :created_at)
    add_ts(:account_session_keys, :updated_at)
    add_ts(:account_verification_keys, :created_at)
    add_ts(:account_verification_keys, :updated_at)

    add_ts(:active_storage_db_files, :updated_at)
    add_ts(:active_storage_variant_records, :created_at)
    add_ts(:active_storage_variant_records, :updated_at)

    add_ts(:comfy_cms_categories, :created_at)
    add_ts(:comfy_cms_categories, :updated_at)
    add_ts(:comfy_cms_categorizations, :created_at)
    add_ts(:comfy_cms_categorizations, :updated_at)
    add_ts(:comfy_cms_revisions, :updated_at)

    add_ts(:comment_hierarchies, :created_at)
    add_ts(:comment_hierarchies, :updated_at)

    add_ts(:friendly_id_slugs, :updated_at)

    add_ts(:oauth_applications, :updated_at)
    add_ts(:oauth_dpop_proofs, :created_at)
    add_ts(:oauth_dpop_proofs, :updated_at)
    add_ts(:oauth_grants, :updated_at)

    add_ts(:thredded_user_topic_follows, :updated_at)
  end

  def down
    remove_ts(:account_active_session_keys, :updated_at)

    remove_ts(:account_login_change_keys, :created_at)
    remove_ts(:account_login_change_keys, :updated_at)
    remove_ts(:account_password_reset_keys, :created_at)
    remove_ts(:account_password_reset_keys, :updated_at)
    remove_ts(:account_remember_keys, :created_at)
    remove_ts(:account_remember_keys, :updated_at)
    remove_ts(:account_session_keys, :created_at)
    remove_ts(:account_session_keys, :updated_at)
    remove_ts(:account_verification_keys, :created_at)
    remove_ts(:account_verification_keys, :updated_at)

    remove_ts(:active_storage_db_files, :updated_at)
    remove_ts(:active_storage_variant_records, :created_at)
    remove_ts(:active_storage_variant_records, :updated_at)

    remove_ts(:comfy_cms_categories, :created_at)
    remove_ts(:comfy_cms_categories, :updated_at)
    remove_ts(:comfy_cms_categorizations, :created_at)
    remove_ts(:comfy_cms_categorizations, :updated_at)
    remove_ts(:comfy_cms_revisions, :updated_at)

    remove_ts(:comment_hierarchies, :created_at)
    remove_ts(:comment_hierarchies, :updated_at)

    remove_ts(:friendly_id_slugs, :updated_at)

    remove_ts(:oauth_applications, :updated_at)
    remove_ts(:oauth_dpop_proofs, :created_at)
    remove_ts(:oauth_dpop_proofs, :updated_at)
    remove_ts(:oauth_grants, :updated_at)

    remove_ts(:thredded_user_topic_follows, :updated_at)
  end

  private

  def add_ts(table, column)
    return unless table_exists?(table)
    return if column_exists?(table, column)

    execute <<~SQL.squish
      ALTER TABLE #{quote_table_name(table)}
      ADD COLUMN #{quote_column_name(column)} DATETIME NULL
    SQL
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

    execute <<~SQL.squish
      ALTER TABLE #{quote_table_name(table)}
      DROP COLUMN #{quote_column_name(column)}
    SQL
  end
end
