# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class AddNotNullConstraintsPart1 < ActiveRecord::Migration[8.1]
  def change
    set_not_null(:comfy_cms_fragments, :record_id)
    set_not_null(:comfy_cms_fragments, :record_type)
    set_not_null(:comfy_cms_pages, :layout_id)
    set_not_null(:comfy_cms_revisions, :created_at)
    set_not_null(:comfy_cms_translations, :layout_id)

    set_not_null(:experiences, :title)

    set_not_null(:friendly_id_slugs, :created_at)
    set_not_null(:friendly_id_slugs, :sluggable_type)

    set_not_null(:indexed_content_vectors, :vector_data)

    set_not_null(:moderation_logs, :content)
    set_not_null(:moderation_logs, :field)
    set_not_null(:moderation_logs, :model_type)
    set_not_null(:moderation_logs, :reason)

    set_not_null(:oauth_grants, :account_id)
    set_not_null(:oauth_grants, :acr)
    set_not_null(:oauth_grants, :certificate_thumbprint)
    set_not_null(:oauth_grants, :claims)
    set_not_null(:oauth_grants, :claims_locales)
    set_not_null(:oauth_grants, :code)
    set_not_null(:oauth_grants, :code_challenge)
    set_not_null(:oauth_grants, :code_challenge_method)
    set_not_null(:oauth_grants, :dpop_jkt)
    set_not_null(:oauth_grants, :dpop_jwk)
    set_not_null(:oauth_grants, :last_polled_at)
    set_not_null(:oauth_grants, :nonce)
    set_not_null(:oauth_grants, :oauth_application_id)
    set_not_null(:oauth_grants, :redirect_uri)
    set_not_null(:oauth_grants, :refresh_token)
    set_not_null(:oauth_grants, :resource)
    set_not_null(:oauth_grants, :revoked_at)
    set_not_null(:oauth_grants, :token)
    set_not_null(:oauth_grants, :user_code)

    set_not_null(:thredded_messageboard_groups, :name)
    set_not_null(:thredded_posts, :content)
    set_not_null(:thredded_post_moderation_records, :messageboard_id)
    set_not_null(:thredded_private_posts, :content)
    set_not_null(:thredded_private_users, :private_topic_id)
    set_not_null(:thredded_private_users, :user_id)
  end

  private

  def set_not_null(table, column)
    return unless table_exists?(table)
    return unless column_exists?(table, column)

    change_column_null(table, column, false)
  end
end
