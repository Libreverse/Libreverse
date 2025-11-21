# frozen_string_literal: true
# shareable_constant_value: literal

class AddOnDeleteCascadeToUserPreferencesFk < ActiveRecord::Migration[8.0]
  def up
    # Only proceed if the FK exists with a different on_delete behavior
    if foreign_key_exists?(:user_preferences, :accounts)
      # Drop the existing FK and recreate with on_delete: :cascade
      remove_foreign_key :user_preferences, :accounts
    end
    add_foreign_key :user_preferences, :accounts, on_delete: :cascade

    # Also ensure an index exists for faster lookups
    add_index :user_preferences, :account_id unless index_exists?(:user_preferences, :account_id)
  end

  def down
    # Revert to default (no cascade)
    remove_foreign_key :user_preferences, :accounts if foreign_key_exists?(:user_preferences, :accounts)
    add_foreign_key :user_preferences, :accounts
  end
end
