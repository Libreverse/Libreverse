# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class AddMissingUniqueIndexesPart1 < ActiveRecord::Migration[8.1]
  def change
    add_unique_index(:comfy_cms_fragments, %i[record_type record_id identifier],
                     name: "idx_comfy_cms_fragments_unique_record_identifier")

    add_unique_index(:comfy_cms_sites, %i[identifier],
                     name: "idx_comfy_cms_sites_unique_identifier")

    add_unique_index(:comfy_cms_sites, %i[path hostname],
                     name: "idx_comfy_cms_sites_unique_path_hostname")

    add_unique_index(:comfy_cms_translations, %i[page_id locale],
                     name: "idx_comfy_cms_translations_unique_page_locale")

    add_unique_index(:accounts_roles, %i[account_id role_id],
                     name: "idx_accounts_roles_unique_account_role")
  end

  private

  def add_unique_index(table_name, columns, name:)
    return if index_exists?(table_name, columns, unique: true, name: name)

    add_index(table_name, columns, unique: true, name: name)
  end
end
