# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

Rails.application.config.to_prepare do
  if defined?(ActiveHashcash::Stamp)
    ActiveHashcash::Stamp.class_eval do
      validates :ext, presence: true
      validates :counter, :ext, :ip_address, :rand, :request_path, :resource, :version,
                length: { maximum: 255 }, allow_blank: true
    end
  end

  if defined?(Audits1984::Audit)
    Audits1984::Audit.class_eval do
      validates :status, presence: true
      validates :notes, length: { maximum: 65_535 }, allow_blank: true
    end
  end

  if defined?(Console1984::User)
    Console1984::User.class_eval do
      validates :username, presence: true
      validates :username, length: { maximum: 255 }
    end
  end

  if defined?(Federails::Activity)
    Federails::Activity.class_eval do
      validates :action, presence: true
      validates :action, :entity_type, :uuid, length: { maximum: 255 }, allow_blank: true
    end
  end

  if defined?(Federails::Actor)
    Federails::Actor.class_eval do
      validates :local, inclusion: { in: [ true, false ] }
      validates :actor_type, :entity_type, :followers_url, :followings_url, :inbox_url,
                :name, :outbox_url, :profile_url, :server, :username, :uuid,
                length: { maximum: 255 }, allow_blank: true
      validates :federated_url, length: { maximum: 500 }, allow_blank: true
      validates :private_key, :public_key, length: { maximum: 65_535 }, allow_blank: true
    end
  end

  if defined?(Federails::Following)
    Federails::Following.class_eval do
      validates :status, presence: true
      validates :federated_url, :uuid, length: { maximum: 255 }, allow_blank: true
    end
  end

  if defined?(FriendlyId::Slug)
    FriendlyId::Slug.class_eval do
      validates :slug, presence: true
      validates :slug, :scope, length: { maximum: 255 }, allow_blank: true
      validates :sluggable_type, length: { maximum: 50 }, allow_blank: true
    end
  end

  if defined?(ActiveStorageDB::File)
    ActiveStorageDB::File.class_eval do
      validates :data, presence: true
      validates :ref, length: { maximum: 255 }, allow_blank: true
    end
  end

  if defined?(Comfy::Cms::File)
    Comfy::Cms::File.class_eval do
      validates :position, presence: true
      validates :label, length: { maximum: 255 }, allow_blank: true
      validates :description, length: { maximum: 65_535 }, allow_blank: true
    end
  end

  if defined?(Comfy::Cms::Fragment)
    Comfy::Cms::Fragment.class_eval do
      validates :boolean, inclusion: { in: [ true, false ] }
      validates :tag, presence: true
      validates :identifier, :record_type, :tag, length: { maximum: 255 }, allow_blank: true
      validates :content, length: { maximum: 16_777_215 }, allow_blank: true
    end
  end

  if defined?(Comfy::Cms::Categorization)
    Comfy::Cms::Categorization.class_eval do
      validates :categorized_type, length: { maximum: 255 }, allow_blank: true
    end
  end

  if defined?(Comfy::Cms::Category)
    Comfy::Cms::Category.class_eval do
      validates :categorized_type, :label, length: { maximum: 255 }, allow_blank: true
    end
  end

  if defined?(Comfy::Cms::Layout)
    Comfy::Cms::Layout.class_eval do
      validates :position, presence: true
      validates :app_layout, :identifier, :label, length: { maximum: 255 }, allow_blank: true
      validates :content, :css, :js, length: { maximum: 16_777_215 }, allow_blank: true
    end
  end

  if defined?(Comfy::Cms::Page)
    Comfy::Cms::Page.class_eval do
      validates :full_path, :position, presence: true
      validates :is_published, inclusion: { in: [ true, false ] }
      validates :full_path, :label, :slug, length: { maximum: 255 }, allow_blank: true
      validates :content_cache, length: { maximum: 16_777_215 }, allow_blank: true
    end
  end

  if defined?(Comfy::Cms::Revision)
    Comfy::Cms::Revision.class_eval do
      validates :record_type, length: { maximum: 255 }, allow_blank: true
      validates :data, length: { maximum: 16_777_215 }, allow_blank: true
    end
  end

  if defined?(Comfy::Cms::Site)
    Comfy::Cms::Site.class_eval do
      validates :locale, presence: true
      validates :hostname, :identifier, :label, :locale, :path, length: { maximum: 255 }, allow_blank: true
    end
  end

  if defined?(Comfy::Cms::Snippet)
    Comfy::Cms::Snippet.class_eval do
      validates :position, presence: true
      validates :identifier, :label, length: { maximum: 255 }, allow_blank: true
      validates :content, length: { maximum: 16_777_215 }, allow_blank: true
    end
  end

  if defined?(Comfy::Cms::Translation)
    Comfy::Cms::Translation.class_eval do
      validates :is_published, inclusion: { in: [ true, false ] }
      validates :label, :locale, length: { maximum: 255 }, allow_blank: true
      validates :content_cache, length: { maximum: 16_777_215 }, allow_blank: true
    end
  end

  if defined?(Comment) && Comment.respond_to?(:hierarchy_class)
    Comment.hierarchy_class.class_eval do
      validates :id, :generations, presence: true
    end
  end

  if defined?(Thredded::Category)
    Thredded::Category.class_eval do
      validates :slug, presence: true
      validates :name, :slug, length: { maximum: 191 }, allow_blank: true
      validates :description, length: { maximum: 65_535 }, allow_blank: true

      has_many :topic_categories, inverse_of: :category, dependent: :destroy
    end
  end

  if defined?(Thredded::Messageboard)
    Thredded::Messageboard.class_eval do
      validates :locked, inclusion: { in: [ true, false ] }
      validates :slug, length: { maximum: 191 }, allow_blank: true
      validates :description, length: { maximum: 65_535 }, allow_blank: true

      has_many :user_topic_read_states,
               class_name: "Thredded::UserTopicReadState",
               inverse_of: :messageboard,
               dependent: :destroy
      has_many :post_moderation_records, inverse_of: :messageboard, dependent: :destroy
    end
  end

  if defined?(Thredded::MessageboardGroup)
    Thredded::MessageboardGroup.class_eval do
      validates :name, length: { maximum: 255 }, allow_blank: true
    end
  end

  if defined?(Thredded::MessageboardNotificationsForFollowedTopics)
    Thredded::MessageboardNotificationsForFollowedTopics.class_eval do
      validates :enabled, inclusion: { in: [ true, false ] }
      validates :notifier_key, presence: true
      validates :notifier_key, length: { maximum: 90 }, allow_blank: true
    end
  end

  if defined?(Thredded::MessageboardUser)
    Thredded::MessageboardUser.class_eval do
      validates :last_seen_at, presence: true
    end
  end

  if defined?(Thredded::NotificationsForFollowedTopics)
    Thredded::NotificationsForFollowedTopics.class_eval do
      validates :enabled, inclusion: { in: [ true, false ] }
      validates :notifier_key, presence: true
      validates :notifier_key, length: { maximum: 90 }, allow_blank: true
    end
  end

  if defined?(Thredded::NotificationsForPrivateTopics)
    Thredded::NotificationsForPrivateTopics.class_eval do
      validates :enabled, inclusion: { in: [ true, false ] }
      validates :notifier_key, presence: true
      validates :notifier_key, length: { maximum: 90 }, allow_blank: true
    end
  end

  if defined?(Thredded::Post)
    Thredded::Post.class_eval do
      validates :content, presence: true
      validates :content, length: { maximum: 65_535 }, allow_blank: true
      validates :source, length: { maximum: 191 }, allow_blank: true
    end
  end

  if defined?(Thredded::PostModerationRecord)
    Thredded::PostModerationRecord.class_eval do
      validates :messageboard_id, presence: true
      validates :post_content, :post_user_name, length: { maximum: 65_535 }, allow_blank: true
    end
  end

  if defined?(Thredded::PrivatePost)
    Thredded::PrivatePost.class_eval do
      validates :content, presence: true
      validates :content, length: { maximum: 65_535 }, allow_blank: true
    end
  end

  if defined?(Thredded::PrivateTopic)
    Thredded::PrivateTopic.class_eval do
      validates :slug, presence: true
      validates :hash_id, length: { maximum: 20 }, allow_blank: true
      validates :slug, :title, length: { maximum: 191 }, allow_blank: true

      has_many :private_users, inverse_of: :private_topic, dependent: :destroy
      has_many :user_read_states,
               class_name: "Thredded::UserPrivateTopicReadState",
               foreign_key: :postable_id,
               inverse_of: :postable,
               dependent: :destroy
    end
  end

  if defined?(Thredded::Topic)
    Thredded::Topic.class_eval do
      validates :slug, presence: true
      validates :locked, :sticky, inclusion: { in: [ true, false ] }
      validates :hash_id, length: { maximum: 20 }, allow_blank: true
      validates :slug, :title, length: { maximum: 191 }, allow_blank: true

      has_many :topic_categories, inverse_of: :topic, dependent: :destroy
      has_many :user_read_states,
               class_name: "Thredded::UserTopicReadState",
               foreign_key: :postable_id,
               inverse_of: :postable,
               dependent: :destroy
    end
  end

  if defined?(Thredded::UserMessageboardPreference)
    Thredded::UserMessageboardPreference.class_eval do
      validates :auto_follow_topics, :follow_topics_on_mention, inclusion: { in: [ true, false ] }
    end
  end

  if defined?(Thredded::UserPostNotification)
    Thredded::UserPostNotification.class_eval do
      validates :notified_at, presence: true
    end
  end

  if defined?(Thredded::UserDetail)
    Thredded::UserDetail.class_eval do
      has_many :messageboard_users,
               class_name: "Thredded::MessageboardUser",
               foreign_key: :thredded_user_detail_id,
               inverse_of: :user_detail,
               dependent: :destroy
    end
  end

  if defined?(Thredded::UserPreference)
    Thredded::UserPreference.class_eval do
      validates :auto_follow_topics, :follow_topics_on_mention, inclusion: { in: [ true, false ] }
    end
  end

  if defined?(Console1984::Command)
    Console1984::Command.class_eval do
      validates :statements, length: { maximum: 65_535 }, allow_blank: true
    end
  end

  if defined?(Console1984::SensitiveAccess)
    Console1984::SensitiveAccess.class_eval do
      validates :justification, length: { maximum: 65_535 }, allow_blank: true
    end
  end

  if defined?(Console1984::Session)
    Console1984::Session.class_eval do
      validates :reason, length: { maximum: 65_535 }, allow_blank: true
    end
  end

  if defined?(Federails::Moderation::DomainBlock)
    Federails::Moderation::DomainBlock.class_eval do
      validates :domain, length: { maximum: 255 }, allow_blank: true
    end
  end

  if defined?(Federails::Moderation::Report)
    Federails::Moderation::Report.class_eval do
      validates :federated_url, :object_type, length: { maximum: 255 }, allow_blank: true
      validates :content, :resolution, length: { maximum: 65_535 }, allow_blank: true
    end
  end

  if defined?(ModerationLog)
    ModerationLog.class_eval do
      validates :field, :model_type, :reason, length: { maximum: 255 }, allow_blank: true
      validates :content, :violations_data, length: { maximum: 65_535 }, allow_blank: true
    end
  end

  if defined?(Role)
    Role.class_eval do
      validates :name, :resource_type, length: { maximum: 255 }, allow_blank: true
    end
  end

  if defined?(Thredded::UserPrivateTopicReadState)
    Thredded::UserPrivateTopicReadState.class_eval do
      validates :integer, :read_at, :read_posts_count, :unread_posts_count, presence: true
    end
  end

  if defined?(Thredded::UserTopicReadState)
    Thredded::UserTopicReadState.class_eval do
      validates :integer, :read_at, :read_posts_count, :unread_posts_count, presence: true
    end
  end
end
