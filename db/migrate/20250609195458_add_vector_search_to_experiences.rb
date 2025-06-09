# frozen_string_literal: true

class AddVectorSearchToExperiences < ActiveRecord::Migration[8.0]
  def up
    # Add embedding column to store vector embeddings as JSON
    add_column :experiences, :embedding, :text

    # Add index for regular text search as fallback on title and description
    add_index :experiences, :title, name: 'index_experiences_on_title_text'
    add_index :experiences, :description, name: 'index_experiences_on_description_text'
  end

  def down
    # Remove the embedding column
    remove_column :experiences, :embedding

    # Remove the text indexes
    remove_index :experiences, name: 'index_experiences_on_title_text'
    remove_index :experiences, name: 'index_experiences_on_description_text'
  end
end
