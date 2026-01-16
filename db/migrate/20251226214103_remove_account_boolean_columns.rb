# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

class RemoveAccountBooleanColumns < ActiveRecord::Migration[8.1]
  def change
    # Remove old boolean columns that are now handled by FlagShihTzu flags
    # These columns conflict with the FlagShihTzu integration
    remove_column :accounts, :admin, :boolean if column_exists?(:accounts, :admin)
    remove_column :accounts, :guest, :boolean if column_exists?(:accounts, :guest)
  end
end
