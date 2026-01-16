# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

class CreateFederatedAnnouncements < ActiveRecord::Migration[8.0]
  def change
    create_table :federated_announcements do |t|
      t.string :activitypub_uri, null: false
      t.string :title, limit: 255
      t.string :source_domain, null: false
      t.datetime :announced_at, null: false
      t.string :experience_url

      t.timestamps
    end

    add_index :federated_announcements, :activitypub_uri, unique: true
    add_index :federated_announcements, :source_domain
    add_index :federated_announcements, :announced_at
  end
end
