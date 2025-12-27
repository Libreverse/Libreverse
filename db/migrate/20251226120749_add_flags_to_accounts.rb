class AddFlagsToAccounts < ActiveRecord::Migration[8.1]
  def change
    # Add flags column for FlagShihTzu bit field storage
    # Bit positions: 1=admin, 2=guest
    add_column :accounts, :flags, :integer, null: false, default: 0
  end
end
