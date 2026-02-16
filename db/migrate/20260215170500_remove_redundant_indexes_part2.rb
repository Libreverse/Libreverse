# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class RemoveRedundantIndexesPart2 < ActiveRecord::Migration[8.1]
  def change
    remove_idx(:thredded_private_posts, :index_thredded_private_posts_on_postable_id)
    remove_idx(:thredded_posts, :index_thredded_posts_on_messageboard_id)
    remove_idx(:thredded_posts, :index_thredded_posts_on_postable_id)
    remove_idx(:thredded_post_moderation_records, :index_thredded_post_moderation_records_on_messageboard_id)
    remove_idx(:thredded_notifications_for_private_topics, :index_thredded_notifications_for_private_topics_on_user_id)
    remove_idx(:thredded_messageboard_users, :index_thredded_messageboard_users_on_thredded_messageboard_id)

    remove_idx(:roles, :index_roles_on_name)
    remove_idx(:oauth_pushed_requests, :index_oauth_pushed_requests_on_oauth_application_id_and_code)
    remove_idx(:indexed_contents, :index_indexed_contents_on_source_platform)

    remove_idx(:friendly_id_slugs, :index_friendly_id_slugs_on_sluggable_id)
    remove_idx(:federails_followings, :index_federails_followings_on_actor_id)
    remove_idx(:federails_followings, :index_federails_followings_on_target_actor_id)

    remove_idx(:experiences, :index_experiences_on_account_id)
    remove_idx(:experiences, :index_experiences_on_source_type)

    remove_idx(:console1984_sessions, :index_console1984_sessions_on_user_id)
    remove_idx(:console1984_commands, :index_console1984_commands_on_session_id)

    remove_idx(:comment_likes, :index_comment_likes_on_comment_id)

    remove_idx(:comfy_cms_translations, :index_comfy_cms_translations_on_page_id)
    remove_idx(:comfy_cms_snippets, :index_comfy_cms_snippets_on_site_id)
    remove_idx(:comfy_cms_pages, :index_comfy_cms_pages_on_parent_id)
    remove_idx(:comfy_cms_pages, :index_comfy_cms_pages_on_site_id)
    remove_idx(:comfy_cms_layouts, :index_comfy_cms_layouts_on_parent_id)
    remove_idx(:comfy_cms_layouts, :index_comfy_cms_layouts_on_site_id)
    remove_idx(:comfy_cms_fragments, :index_comfy_cms_fragments_on_record_type_and_record_id)
    remove_idx(:comfy_cms_files, :index_comfy_cms_files_on_site_id)
    remove_idx(:comfy_cms_categorizations, :index_comfy_cms_categorizations_on_category_id)
    remove_idx(:comfy_cms_categories, :index_comfy_cms_categories_on_site_id)
  end

  private

  def remove_idx(table, index_name)
    return unless index_exists?(table, name: index_name)

    remove_index(table, name: index_name)
  rescue ActiveRecord::StatementInvalid => e
    Rails.logger.info("Skipping index #{index_name} on #{table}: #{e.message}")
  end
end
