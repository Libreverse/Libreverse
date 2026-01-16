# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

class CreateInstanceSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :instance_settings do |t|
      t.string :key, null: false
      t.text :value
      t.text :description

      t.timestamps
    end

    add_index :instance_settings, :key, unique: true
  end
end
