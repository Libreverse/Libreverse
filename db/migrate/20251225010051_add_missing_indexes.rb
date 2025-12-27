class AddMissingIndexes < ActiveRecord::Migration[8.1]
  def change
    # Active Storage indexes
    add_index :active_storage_attachments, [:record_id, :record_type] unless index_exists?(:active_storage_attachments, [:record_id, :record_type])
    add_index :active_storage_variant_records, :blob_id unless index_exists?(:active_storage_variant_records, :blob_id)
    
    # Comfy CMS indexes
    add_index :comfy_cms_categories, :site_id unless index_exists?(:comfy_cms_categories, :site_id)
    add_index :comfy_cms_categorizations, :category_id unless index_exists?(:comfy_cms_categorizations, :category_id)
    add_index :comfy_cms_categorizations, [:categorized_id, :categorized_type] unless index_exists?(:comfy_cms_categorizations, [:categorized_id, :categorized_type])
    add_index :comfy_cms_files, :site_id unless index_exists?(:comfy_cms_files, :site_id)
    add_index :comfy_cms_layouts, :parent_id unless index_exists?(:comfy_cms_layouts, :parent_id)
    add_index :comfy_cms_layouts, :site_id unless index_exists?(:comfy_cms_layouts, :site_id)
    add_index :comfy_cms_pages, :layout_id unless index_exists?(:comfy_cms_pages, :layout_id)
    add_index :comfy_cms_pages, :parent_id unless index_exists?(:comfy_cms_pages, :parent_id)
    add_index :comfy_cms_pages, :site_id unless index_exists?(:comfy_cms_pages, :site_id)
    add_index :comfy_cms_pages, :target_page_id unless index_exists?(:comfy_cms_pages, :target_page_id)
    add_index :comfy_cms_revisions, [:record_id, :record_type] unless index_exists?(:comfy_cms_revisions, [:record_id, :record_type])
    add_index :comfy_cms_snippets, :site_id unless index_exists?(:comfy_cms_snippets, :site_id)
    add_index :comfy_cms_translations, :layout_id unless index_exists?(:comfy_cms_translations, :layout_id)
    
    # Console1984 indexes
    add_index :console1984_commands, :session_id unless index_exists?(:console1984_commands, :session_id)
    add_index :console1984_sessions, :user_id unless index_exists?(:console1984_sessions, :user_id)
    
    # Federails indexes
    add_index :federails_followings, [:actor_id, :target_actor_id] unless index_exists?(:federails_followings, [:actor_id, :target_actor_id])
    add_index :federails_followings, [:target_actor_id, :actor_id] unless index_exists?(:federails_followings, [:target_actor_id, :actor_id])
    
    # Friendly ID indexes
    add_index :friendly_id_slugs, [:sluggable_id, :sluggable_type] unless index_exists?(:friendly_id_slugs, [:sluggable_id, :sluggable_type])
    
    # Basic Thredded indexes
    add_index :thredded_messageboard_users, :thredded_messageboard_id unless index_exists?(:thredded_messageboard_users, :thredded_messageboard_id)
    add_index :thredded_messageboards, :last_topic_id unless index_exists?(:thredded_messageboards, :last_topic_id)
    add_index :thredded_notifications_for_private_topics, :user_id unless index_exists?(:thredded_notifications_for_private_topics, :user_id)
    add_index :thredded_post_moderation_records, :messageboard_id unless index_exists?(:thredded_post_moderation_records, :messageboard_id)
    add_index :thredded_post_moderation_records, :moderator_id unless index_exists?(:thredded_post_moderation_records, :moderator_id)
    add_index :thredded_post_moderation_records, :post_id unless index_exists?(:thredded_post_moderation_records, :post_id)
    add_index :thredded_post_moderation_records, :post_user_id unless index_exists?(:thredded_post_moderation_records, :post_user_id)
    add_index :thredded_posts, [:messageboard_id, :user_id] unless index_exists?(:thredded_posts, [:messageboard_id, :user_id])
    add_index :thredded_private_posts, :postable_id unless index_exists?(:thredded_private_posts, :postable_id)
    add_index :thredded_private_posts, :user_id unless index_exists?(:thredded_private_posts, :user_id)
    add_index :thredded_private_topics, :last_user_id unless index_exists?(:thredded_private_topics, :last_user_id)
    add_index :thredded_private_topics, :user_id unless index_exists?(:thredded_private_topics, :user_id)
  end
end
