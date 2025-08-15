# frozen_string_literal: true

class DropCollaborativeDocumentsTables < ActiveRecord::Migration[7.1]
  def up
    drop_table :collaborative_document_updates, if_exists: true
    drop_table :collaborative_documents, if_exists: true
    drop_table :session_finalizations, if_exists: true
  end

  def down
    # Intentionally left blank (tables removed permanently in alpha simplification)
  end
end
