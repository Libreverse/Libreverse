# frozen_string_literal: true

class AddUniqueIndexesToVectors < ActiveRecord::Migration[8.0]
  def change
    add_index :indexed_content_vectors, %i[vector_hash indexed_content_id], unique: true, name: 'idx_icv_on_vh_and_icid'
  end
end
