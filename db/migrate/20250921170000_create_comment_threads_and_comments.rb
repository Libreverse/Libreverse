# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class CreateCommentThreadsAndComments < ActiveRecord::Migration[7.1]
  def change
  create_table :comment_threads, if_not_exists: true do |t|
      t.string  :commontable_type, null: false
      t.bigint  :commontable_id,   null: false
      t.integer :comments_count,   null: false, default: 0
      t.datetime :locked_at
      t.timestamps
      t.index %i[commontable_type commontable_id], unique: true, name: 'idx_comment_threads_poly'
  end

  create_table :comments, if_not_exists: true do |t|
      t.references :comment_thread, null: false, foreign_key: true
      t.bigint :account_id, null: false
      t.bigint :parent_id
      t.text :body, null: false
  t.json :mentions_cache, null: false
      t.integer :likes_count, null: false, default: 0
      t.datetime :deleted_at
      t.datetime :edited_at
      t.timestamps
      t.index :account_id
      t.index :parent_id
  end

  create_table :comment_likes, if_not_exists: true do |t|
  t.references :comment, null: false, foreign_key: true
      t.bigint :account_id, null: false
      t.timestamps
      t.index %i[comment_id account_id], unique: true
  end
  end
end
