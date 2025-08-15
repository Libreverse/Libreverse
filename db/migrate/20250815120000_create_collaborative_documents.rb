# frozen_string_literal: true

class CreateCollaborativeDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :collaborative_documents do |t|
      t.string  :session_id, null: false
      t.integer :experience_id
      t.binary  :base_snapshot, null: false, default: "".b
      t.jsonb   :version_vector, null: false, default: {}
      t.datetime :finalized_at
      t.timestamps
    end
    add_index :collaborative_documents, :session_id, unique: true

    create_table :collaborative_document_updates do |t|
      t.references :collaborative_document, null: false, foreign_key: { on_delete: :cascade }
      t.integer :seq, null: false
      # Use non-conflicting column name; avoid ActiveRecord#update collision
      t.binary  :ops, null: false
      t.timestamps
    end
    add_index :collaborative_document_updates, %i[collaborative_document_id seq], unique: true, name: "idx_doc_seq"

    create_table :session_finalizations do |t|
      t.string :session_id, null: false
      t.jsonb  :transient_state, null: false, default: {}
      t.jsonb  :yjs_vector, null: false, default: {}
      t.datetime :created_at, null: false
    end
    add_index :session_finalizations, :session_id, unique: true
  end
end
