# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

class RemoveOldBooleanColumnsFromExperiences < ActiveRecord::Migration[8.1]
  def change
    # Remove old boolean columns that are now handled by FlagShihTzu flags
    remove_column :experiences, :approved, :boolean
    remove_column :experiences, :federate, :boolean
    remove_column :experiences, :federated_blocked, :boolean
    remove_column :experiences, :offline_available, :boolean
  end
end
