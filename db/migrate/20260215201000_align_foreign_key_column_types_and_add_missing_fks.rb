# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class AlignForeignKeyColumnTypesAndAddMissingFks < ActiveRecord::Migration[8.1]
  def up
    align_column_types
    add_missing_columns
    add_indexes
    add_missing_foreign_keys
  end

  def down
    remove_foreign_key :thredded_notifications_for_followed_topics, column: :messageboard_id if foreign_key_exists?(:thredded_notifications_for_followed_topics, :thredded_messageboards, column: :messageboard_id)
    remove_index :thredded_notifications_for_followed_topics, name: :idx_tnfft_messageboard_id if index_exists?(:thredded_notifications_for_followed_topics, :messageboard_id, name: :idx_tnfft_messageboard_id)
    remove_column :thredded_notifications_for_followed_topics, :messageboard_id if column_exists?(:thredded_notifications_for_followed_topics, :messageboard_id)
  end

  private

  def align_column_types
    change_to_bigint(:comfy_cms_categories, :site_id)
    change_to_bigint(:comfy_cms_categorizations, :category_id)
    change_to_bigint(:comfy_cms_files, :site_id)
    change_to_bigint(:comfy_cms_layouts, :parent_id)
    change_to_bigint(:comfy_cms_layouts, :site_id)
    change_to_bigint(:comfy_cms_pages, :layout_id)
    change_to_bigint(:comfy_cms_pages, :parent_id)
    change_to_bigint(:comfy_cms_pages, :site_id)
    change_to_bigint(:comfy_cms_pages, :target_page_id)
    change_to_bigint(:comfy_cms_snippets, :site_id)
    change_to_bigint(:comfy_cms_translations, :layout_id)
    change_to_bigint(:comfy_cms_translations, :page_id)

    change_to_bigint(:comment_hierarchies, :ancestor_id)
    change_to_bigint(:comment_hierarchies, :descendant_id)
  end

  def add_missing_columns
    add_column :thredded_notifications_for_followed_topics, :messageboard_id, :bigint unless column_exists?(:thredded_notifications_for_followed_topics, :messageboard_id)
  end

  def add_indexes
    add_index :thredded_notifications_for_followed_topics, :messageboard_id, name: :idx_tnfft_messageboard_id unless index_exists?(:thredded_notifications_for_followed_topics, :messageboard_id, name: :idx_tnfft_messageboard_id)
  end

  def add_missing_foreign_keys
    add_fk(:comfy_cms_categorizations, :comfy_cms_categories, :category_id)
    add_fk(:comfy_cms_categories, :comfy_cms_sites, :site_id)
    add_fk(:comfy_cms_files, :comfy_cms_sites, :site_id)
    add_fk(:comfy_cms_layouts, :comfy_cms_layouts, :parent_id)
    add_fk(:comfy_cms_layouts, :comfy_cms_sites, :site_id)
    add_fk(:comfy_cms_pages, :comfy_cms_layouts, :layout_id)
    add_fk(:comfy_cms_pages, :comfy_cms_pages, :parent_id)
    add_fk(:comfy_cms_pages, :comfy_cms_sites, :site_id)
    add_fk(:comfy_cms_pages, :comfy_cms_pages, :target_page_id)
    add_fk(:comfy_cms_snippets, :comfy_cms_sites, :site_id)
    add_fk(:comfy_cms_translations, :comfy_cms_layouts, :layout_id)
    add_fk(:comfy_cms_translations, :comfy_cms_pages, :page_id)

    add_fk(:comment_hierarchies, :comments, :ancestor_id)
    add_fk(:comment_hierarchies, :comments, :descendant_id)

    add_fk(:thredded_notifications_for_followed_topics, :thredded_messageboards, :messageboard_id)
  end

  def change_to_bigint(table, column)
    return unless column_exists?(table, column)

    existing = connection.columns(table).find { |c| c.name == column.to_s }
    return if existing.nil? || (existing.type == :integer && existing.limit == 8)

    change_column table, column, :bigint
  end

  def add_fk(from_table, to_table, column)
    return unless table_exists?(from_table) && table_exists?(to_table)
    return unless column_exists?(from_table, column)
    return if foreign_key_exists?(from_table, to_table, column: column)

    add_foreign_key from_table, to_table, column: column
  end
end
