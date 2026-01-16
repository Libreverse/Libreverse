# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

# This migration comes from federails (originally 20250329123940)
class AddTombstonedAtToActors < ActiveRecord::Migration[7.0]
  def change
    add_column :federails_actors, :tombstoned_at, :datetime
    add_index  :federails_actors, :tombstoned_at
  end
end
