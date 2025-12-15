# frozen_string_literal: true
# shareable_constant_value: literal

class AddCurrentStateToExperiences < ActiveRecord::Migration[8.1]
  def change
    add_column :experiences, :current_state, :json
  end
end
