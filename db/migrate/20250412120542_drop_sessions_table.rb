# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

class DropSessionsTable < ActiveRecord::Migration[8.0]
  def change
    reversible do |dir|
      dir.up do
        # Explicitly drop unused session tables
        %i[sessions sessions_table_for_active_record_stores].each do |tbl|
          drop_table tbl, if_exists: true
        end
      end
      dir.down do
        # This migration is intended to drop the table.
        # Recreating it would require knowing the previous schema.
        # If reversal is truly needed, this block should be filled in.
        # For now, we raise an error to prevent accidental reversal without the schema.
        raise ActiveRecord::IrreversibleMigration, "Cannot recreate the sessions table automatically."
      end
    end
  end
end
