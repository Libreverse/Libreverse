class RemoveOldBooleanColumnsFromAccounts < ActiveRecord::Migration[8.1]
  def change
    # Columns already removed in previous failed migration
    # This migration is now a no-op
  end
end
