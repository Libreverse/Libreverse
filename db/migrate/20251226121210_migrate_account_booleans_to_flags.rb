# frozen_string_literal: true
# shareable_constant_value: literal

class MigrateAccountBooleansToFlags < ActiveRecord::Migration[8.1]
  def up
    # Migrate existing boolean data to flags bit field
    # Bit positions: 1=admin, 2=guest

    Account.find_each do |account|
      flags = 0
      flags |= 1 if account.admin?
      flags |= 2 if account.guest?

      account.update_columns(flags: flags)
    end
  end

  def down
    # Revert by setting all flags to 0
    Account.update_all(flags: 0)
  end
end
