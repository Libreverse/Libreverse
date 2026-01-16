# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class AddIndexOnGuestAndCreatedAtToAccounts < ActiveRecord::Migration[8.0]
  def up
    add_index :accounts, %i[guest created_at], name: "index_accounts_on_guest_and_created_at"
  end

  def down
    remove_index :accounts, name: "index_accounts_on_guest_and_created_at"
  end
end
