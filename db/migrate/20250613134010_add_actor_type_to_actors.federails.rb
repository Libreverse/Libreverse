# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# This migration comes from federails (originally 20250329123939)
class AddActorTypeToActors < ActiveRecord::Migration[7.2]
  def change
    add_column :federails_actors, :actor_type, :string, null: true
  end
end
