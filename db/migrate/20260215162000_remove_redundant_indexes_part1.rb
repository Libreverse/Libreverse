# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class RemoveRedundantIndexesPart1 < ActiveRecord::Migration[8.1]
  def change
    remove_idx(:user_preferences, :index_user_preferences_on_account_id)
    remove_idx(:thredded_messageboard_notifications_for_followed_topics, :idx_on_user_id_78e6269133)
    remove_idx(:thredded_categories, :index_thredded_categories_on_messageboard_id)
  end

  private

  def remove_idx(table, index_name)
    return unless index_exists?(table, name: index_name)

    remove_index(table, name: index_name)
  end
end
