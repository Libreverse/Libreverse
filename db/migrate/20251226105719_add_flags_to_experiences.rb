# frozen_string_literal: true
# shareable_constant_value: literal

class AddFlagsToExperiences < ActiveRecord::Migration[8.1]
  def change
    # Add flags column for FlagShihTzu bit field storage
    # Bit positions: 1=approved, 2=federate, 4=federated_blocked, 8=offline_available
    add_column :experiences, :flags, :integer, null: false, default: 0
  end
end
