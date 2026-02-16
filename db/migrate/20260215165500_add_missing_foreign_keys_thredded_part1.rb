# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class AddMissingForeignKeysThreddedPart1 < ActiveRecord::Migration[8.1]
  def change
    add_fk(:thredded_categories, :thredded_messageboards, column: :messageboard_id)

    add_fk(:thredded_messageboards, :thredded_topics, column: :last_topic_id)
    add_fk(:thredded_messageboards, :thredded_messageboard_groups, column: :messageboard_group_id)

    add_fk(:thredded_messageboard_notifications_for_followed_topics, :accounts, column: :user_id)
    add_fk(:thredded_messageboard_notifications_for_followed_topics, :thredded_messageboards, column: :messageboard_id)

    add_fk(:thredded_notifications_for_followed_topics, :accounts, column: :user_id)
    add_fk(:thredded_notifications_for_private_topics, :accounts, column: :user_id)

    add_fk(:thredded_posts, :accounts, column: :user_id)
    add_fk(:thredded_posts, :thredded_messageboards, column: :messageboard_id)
    add_fk(:thredded_posts, :thredded_topics, column: :postable_id)

    add_fk(:thredded_post_moderation_records, :thredded_messageboards, column: :messageboard_id)
    add_fk(:thredded_post_moderation_records, :thredded_posts, column: :post_id)
    add_fk(:thredded_post_moderation_records, :accounts, column: :post_user_id)
    add_fk(:thredded_post_moderation_records, :accounts, column: :moderator_id)

    add_fk(:thredded_private_posts, :accounts, column: :user_id)
    add_fk(:thredded_private_posts, :thredded_private_topics, column: :postable_id)

    add_fk(:thredded_private_topics, :accounts, column: :last_user_id)
    add_fk(:thredded_private_topics, :accounts, column: :user_id)

    add_fk(:thredded_private_users, :thredded_private_topics, column: :private_topic_id)
    add_fk(:thredded_private_users, :accounts, column: :user_id)

    add_fk(:thredded_topics, :accounts, column: :last_user_id)
    add_fk(:thredded_topics, :accounts, column: :user_id)
    add_fk(:thredded_topics, :thredded_messageboards, column: :messageboard_id)

    add_fk(:thredded_topic_categories, :thredded_categories, column: :category_id)
    add_fk(:thredded_topic_categories, :thredded_topics, column: :topic_id)

    add_fk(:thredded_user_details, :accounts, column: :user_id)

    add_fk(:thredded_user_messageboard_preferences, :accounts, column: :user_id)
    add_fk(:thredded_user_messageboard_preferences, :thredded_messageboards, column: :messageboard_id)

    add_fk(:thredded_user_post_notifications, :thredded_posts, column: :post_id)
    add_fk(:thredded_user_post_notifications, :accounts, column: :user_id)

    add_fk(:thredded_user_preferences, :accounts, column: :user_id)

    add_fk(:thredded_user_private_topic_read_states, :accounts, column: :user_id)
    add_fk(:thredded_user_private_topic_read_states, :thredded_private_topics, column: :postable_id)

    add_fk(:thredded_user_topic_follows, :accounts, column: :user_id)
    add_fk(:thredded_user_topic_follows, :thredded_topics, column: :topic_id)

    add_fk(:thredded_user_topic_read_states, :accounts, column: :user_id)
    add_fk(:thredded_user_topic_read_states, :thredded_topics, column: :postable_id)
    add_fk(:thredded_user_topic_read_states, :thredded_messageboards, column: :messageboard_id)
  end

  private

  def add_fk(from_table, to_table, column:)
    return unless table_exists?(from_table) && table_exists?(to_table)
    return unless column_exists?(from_table, column)
    return if foreign_key_exists?(from_table, to_table, column: column)
    return unless compatible_column_types?(from_table, to_table, column)

    add_foreign_key(from_table, to_table, column: column)
  end

  def compatible_column_types?(from_table, to_table, column)
    from_column = connection.columns(from_table).find { |c| c.name == column.to_s }
    to_column = connection.columns(to_table).find { |c| c.name == "id" }
    return false if from_column.nil? || to_column.nil?

    from_column.type == to_column.type && from_column.limit == to_column.limit
  end
end
