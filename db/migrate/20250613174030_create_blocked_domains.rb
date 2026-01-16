# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

class CreateBlockedDomains < ActiveRecord::Migration[8.0]
  def change
    create_table :blocked_domains do |t|
      t.string :domain, null: false
      t.text :reason
      t.datetime :blocked_at, null: false
      t.string :blocked_by

      t.timestamps
    end

    add_index :blocked_domains, :domain, unique: true
  end
end
