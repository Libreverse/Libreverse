# frozen_string_literal: true

# This migration comes from federails (originally 20241002094501)
class AddKeypairToActors < ActiveRecord::Migration[7.0]
  def change
    change_table :federails_actors do |t|
      t.text :public_key
      t.text :private_key, encrypted: true
    end
  end
end
