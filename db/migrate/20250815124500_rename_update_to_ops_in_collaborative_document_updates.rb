# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class RenameUpdateToOpsInCollaborativeDocumentUpdates < ActiveRecord::Migration[7.1]
  def up
    return unless table_exists?(:collaborative_document_updates)

    return unless column_exists?(:collaborative_document_updates, :update) && !column_exists?(:collaborative_document_updates, :ops)

      rename_column :collaborative_document_updates, :update, :ops
  end

  def down
    return unless table_exists?(:collaborative_document_updates)

    return unless column_exists?(:collaborative_document_updates, :ops) && !column_exists?(:collaborative_document_updates, :update)

      rename_column :collaborative_document_updates, :ops, :update
  end
end
