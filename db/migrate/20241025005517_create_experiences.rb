# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class CreateExperiences < ActiveRecord::Migration[7.1]
  def change
    create_table :experiences do |t|
      t.text :content

      t.timestamps
    end
  end
end
