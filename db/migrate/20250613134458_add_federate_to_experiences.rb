# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

class AddFederateToExperiences < ActiveRecord::Migration[8.0]
  def change
    add_column :experiences, :federate, :boolean, default: true, null: false
  end
end
