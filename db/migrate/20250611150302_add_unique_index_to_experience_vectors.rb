# frozen_string_literal: true

class AddUniqueIndexToExperienceVectors < ActiveRecord::Migration[8.0]
  def change
    add_index :experience_vectors, %i[vector_hash experience_id], unique: true, name: 'index_experience_vectors_on_vector_hash_and_experience_id'
  end
end
