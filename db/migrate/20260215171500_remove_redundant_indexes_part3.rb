# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class RemoveRedundantIndexesPart3 < ActiveRecord::Migration[8.1]
  def change
    remove_idx(:indexed_content_vectors, :idx_icv_on_vh_and_icid)
    remove_idx(:indexed_content_vectors, :index_indexed_content_vectors_on_vector_hash)

    remove_idx(:experience_vectors, :index_experience_vectors_on_vector_hash_and_experience_id)
    remove_idx(:experience_vectors, :index_experience_vectors_on_vector_hash)

    remove_idx(:active_storage_variant_records, :index_active_storage_variant_records_on_blob_id)

    remove_idx(:accounts_roles, :index_accounts_roles_on_account_id_and_role_id)
    remove_idx(:accounts_roles, :index_accounts_roles_on_account_id)
    remove_idx(:account_roles, :index_account_roles_on_account_id)
    remove_idx(:account_active_session_keys, :index_account_active_session_keys_on_account_id_and_session_id)
  end

  private

  def remove_idx(table, index_name)
    return unless index_exists?(table, name: index_name)

    remove_index(table, name: index_name)
  rescue ActiveRecord::StatementInvalid => e
    Rails.logger.info("Skipping index #{index_name} on #{table}: #{e.message}")
  end
end
