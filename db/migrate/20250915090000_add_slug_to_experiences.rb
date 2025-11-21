# frozen_string_literal: true
# shareable_constant_value: literal

class AddSlugToExperiences < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    # Add column if it doesn't already exist
    add_column :experiences, :slug, :string unless column_exists?(:experiences, :slug)

    # Ensure we have a unique index on slug. If a non-unique index exists, replace it.
    return if index_exists?(:experiences, :slug, unique: true)

      remove_index :experiences, :slug if index_exists?(:experiences, :slug)
      add_index :experiences, :slug, unique: true

    # NOTE: Do not backfill here. A dedicated migration (20250915091000) handles
    # generating unique slugs safely, avoiding collisions that would violate the
    # unique index. Keeping this migration limited to schema changes makes it
    # idempotent even if partially applied in non-transactional environments.
  end

  def down
    remove_index :experiences, :slug if index_exists?(:experiences, :slug)
    remove_column :experiences, :slug if column_exists?(:experiences, :slug)
  end
end
