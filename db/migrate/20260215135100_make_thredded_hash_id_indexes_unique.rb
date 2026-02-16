# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class MakeThreddedHashIdIndexesUnique < ActiveRecord::Migration[8.1]
  def change
    make_unique(:thredded_private_topics, :index_thredded_private_topics_on_hash_id,
                %i[hash_id], :idx_thredded_private_topics_unique_hash_id)

    make_unique(:thredded_topics, :index_thredded_topics_on_hash_id,
                %i[hash_id], :idx_thredded_topics_unique_hash_id)
  end

  private

  def make_unique(table_name, old_index_name, columns, new_index_name)
    remove_index(table_name, name: old_index_name) if index_exists?(table_name, columns, name: old_index_name)

    return if index_exists?(table_name, columns, unique: true, name: new_index_name)

    add_index(table_name, columns, unique: true, name: new_index_name)
  end
end
