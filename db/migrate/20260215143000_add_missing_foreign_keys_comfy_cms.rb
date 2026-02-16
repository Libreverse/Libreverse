# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class AddMissingForeignKeysComfyCms < ActiveRecord::Migration[8.1]
  def change
    add_fk(:comfy_cms_categorizations, :comfy_cms_categories, column: :category_id)
    add_fk(:comfy_cms_categories, :comfy_cms_sites, column: :site_id)
    add_fk(:comfy_cms_files, :comfy_cms_sites, column: :site_id)

    add_fk(:comfy_cms_layouts, :comfy_cms_layouts, column: :parent_id)
    add_fk(:comfy_cms_layouts, :comfy_cms_sites, column: :site_id)

    add_fk(:comfy_cms_pages, :comfy_cms_layouts, column: :layout_id)
    add_fk(:comfy_cms_pages, :comfy_cms_pages, column: :parent_id)
    add_fk(:comfy_cms_pages, :comfy_cms_sites, column: :site_id)
    add_fk(:comfy_cms_pages, :comfy_cms_pages, column: :target_page_id)

    add_fk(:comfy_cms_snippets, :comfy_cms_sites, column: :site_id)

    add_fk(:comfy_cms_translations, :comfy_cms_layouts, column: :layout_id)
    add_fk(:comfy_cms_translations, :comfy_cms_pages, column: :page_id)
  end

  private

  def add_fk(from_table, to_table, column:)
    return unless column_exists?(from_table, column)
    return if foreign_key_exists?(from_table, to_table, column: column)
    return unless compatible_column_types?(from_table, to_table, column)

    add_foreign_key(from_table, to_table, column: column)
  end

  def compatible_column_types?(from_table, to_table, column)
    from_column = connection.columns(from_table).find { |c| c.name == column.to_s }
    to_column = connection.columns(to_table).find { |c| c.name == "id" }
    return false if from_column.nil? || to_column.nil?

    from_column.type == to_column.type && from_column.limit == to_column.limit
  end
end
