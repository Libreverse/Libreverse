# frozen_string_literal: true

class AddVectorDataToIndexedContentVectors < ActiveRecord::Migration[8.0]
  def change
    add_column :indexed_content_vectors, :vector_data, :text
  end
end
