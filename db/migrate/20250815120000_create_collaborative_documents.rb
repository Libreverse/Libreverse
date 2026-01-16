# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

class CreateCollaborativeDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :collaborative_documents do |t|
      t.string  :session_id, null: false
      t.integer :experience_id
      # MySQL/TiDB do not allow defaults on BLOB/TEXT/JSON columns. Provide
      # application-level defaults instead.
      t.binary  :base_snapshot, null: false
      # jsonb is Postgres-only; use :json. No DB default for portability.
      t.json    :version_vector, null: false
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
  t.json  :transient_state, null: false
  t.json  :yjs_vector, null: false
      t.datetime :created_at, null: false
    end
    add_index :session_finalizations, :session_id, unique: true
  end
end
