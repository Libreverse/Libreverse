# This migration comes from federails (originally 20200712133150)
class CreateFederailsActors < ActiveRecord::Migration[7.0]
  def change
    create_table :federails_actors do |t|
      t.string :name
      t.string :federated_url, limit: 500
      t.string :username
      t.string :server
      t.string :inbox_url
      t.string :outbox_url
      t.string :followers_url
      t.string :followings_url
      t.string :profile_url

      t.integer :entity_id, null: true
      t.string :entity_type, null: true

      t.timestamps
      t.index :federated_url, unique: true
      t.index %i[entity_type entity_id], name: 'index_federails_actors_on_entity', unique: true
    end
  end
end
