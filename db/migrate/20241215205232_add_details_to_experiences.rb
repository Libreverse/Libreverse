# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

class AddDetailsToExperiences < ActiveRecord::Migration[8.0]
  def change
    change_table :experiences, bulk: true do |t|
      t.string :title
      t.text :description
      t.string :author
    end
  end
end
