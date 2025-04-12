class DropSessionsTable < ActiveRecord::Migration[8.0]
  def change
    reversible do |dir|
      dir.up do
        # Explicitly drop the table when migrating up
        drop_table :sessions, if_exists: true # Add if_exists for safety
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
