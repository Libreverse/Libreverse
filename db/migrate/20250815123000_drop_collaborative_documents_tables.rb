# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

class DropCollaborativeDocumentsTables < ActiveRecord::Migration[7.1]
  def up
  # This migration originally removed the collaborative documents feature.
  # It now no-ops to preserve the recreated tables. Set DROP_COLLAB_DOCS=1
  # to execute the original destructive behavior.
  return unless ENV["DROP_COLLAB_DOCS"] == "1"

  drop_table :collaborative_document_updates, if_exists: true
  drop_table :collaborative_documents, if_exists: true
  drop_table :session_finalizations, if_exists: true
  end

  def down
    # Intentionally left blank (tables removed permanently in alpha simplification)
  end
end
