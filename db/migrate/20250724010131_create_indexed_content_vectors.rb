class CreateIndexedContentVectors < ActiveRecord::Migration[8.0]
  def change
    create_table :indexed_content_vectors do |t|
      t.references :indexed_content, null: false, foreign_key: true, index: { unique: true }
      t.string :vector_hash, null: false
      t.datetime :generated_at, null: false
      t.text :content_hash, null: false

      t.timestamps
    end

    add_index :indexed_content_vectors, :vector_hash
    add_index :indexed_content_vectors, :generated_at
  end
end
