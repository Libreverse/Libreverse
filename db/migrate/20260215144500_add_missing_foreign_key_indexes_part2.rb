# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class AddMissingForeignKeyIndexesPart2 < ActiveRecord::Migration[8.1]
  def change
    add_idx(:comment_likes, :account_id)
    add_idx(:comments, :approved_by_id)
    add_idx(:thredded_topics, :last_user_id)
    add_idx(:thredded_user_messageboard_preferences, :messageboard_id)
    add_idx(:thredded_user_private_topic_read_states, :postable_id)
    add_idx(:thredded_user_topic_follows, :topic_id)
    add_idx(:thredded_user_topic_read_states, :postable_id)
  end

  private

  def add_idx(table, column)
    return unless column_exists?(table, column)
    return if index_exists?(table, column)

    add_index(table, column)
  end
end
