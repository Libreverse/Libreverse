# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

# == Schema Information
#
# Table name: experiences
#
#  id                    :bigint           not null, primary key
#  author                :string(255)
#  current_state         :json
#  description           :text(65535)
#  flags                 :integer          default(0), not null
#  metaverse_coordinates :text(65535)
#  metaverse_metadata    :text(65535)
#  metaverse_platform    :string(255)
#  slug                  :string(255)
#  source_type           :string(255)      default("user_created"), not null
#  title                 :string(255)      not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :bigint           not null
#  indexed_content_id    :bigint
#
# Indexes
#
#  index_experiences_on_account_id_and_created_at           (account_id,created_at)
#  index_experiences_on_indexed_content_id                  (indexed_content_id)
#  index_experiences_on_metaverse_platform                  (metaverse_platform)
#  index_experiences_on_slug                                (slug) UNIQUE
#  index_experiences_on_source_type_and_metaverse_platform  (source_type,metaverse_platform)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (indexed_content_id => indexed_contents.id)
#
require "active_storage_validations"

class Experience < ApplicationRecord
  extend FriendlyId
  include ActiveStorageValidations::Model
  include GraphqlRails::Model
  include FederatableExperience
  include EncodingNormalizer
  include FlagShihTzu

  # FlagShihTzu bit field configuration
  # Bit positions: 1=approved, 2=federate, 4=federated_blocked, 8=offline_available
  has_flags 1 => :approved,
            2 => :federate,
            4 => :federated_blocked,
            8 => :offline_available

  # Enable SecondLevelCache for automatic read-through/write-through caching
  second_level_cache expires_in: 1.hour

  graphql do |c|
    c.attribute(:id, type: "ID!")
    c.attribute(:title, type: "String!")
    c.attribute(:description, type: "String")
    c.attribute(:author, type: "String")
    c.attribute(:approved, type: "Boolean!")
    c.attribute(:account_id, type: "ID")
    c.attribute(:html_file?, type: "Boolean!")
    c.attribute(:federate, type: "Boolean!")
    c.attribute(:offline_available, type: "Boolean!")
    c.attribute(:created_at, type: "String!")
    c.attribute(:updated_at, type: "String!")
  end

  belongs_to :account, optional: false
  has_one :experience_vector, dependent: :destroy
  has_one_attached :html_file, dependent: :purge_later
  encrypts_attached :html_file

  validates :flags, :source_type, presence: true
  validates :title, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 65_535 }, allow_blank: true
  validates :author, length: { maximum: 255 }
  validates :source_type, :slug, :metaverse_platform, length: { maximum: 255 }, allow_blank: true
  validates :metaverse_coordinates, :metaverse_metadata, length: { maximum: 65_535 }, allow_blank: true
  validates :federate, inclusion: { in: [ true, false ] }
  validates :offline_available, inclusion: { in: [ true, false ] }
  validates :html_file, presence: true,
                        content_type: "text/html",
                        filename: {
                          with: /\A[\w.-]+\z/,
                          message: "only letters, numbers, underscores, dashes and periods are allowed in filenames"
                        }, unless: -> { Rails.env.test? }

  # Content moderation validation
  validate :content_moderation

  # Force UTF-8 encoding prior to other validations (defensive for binary fixtures)
  before_validation :force_utf8_encoding, prepend: true
  # Normalize encoding for user-provided textual fields to avoid transliteration errors
  normalize_encoding_for :title, :description, :author

  # Ensure an owner is always associated
  before_validation :assign_owner, on: :create

  # Add a scope for approved experiences using FlagShihTzu
  scope :approved, -> { where("flags & 1 != 0") } # Check approved flag (bit position 1)
  scope :pending_approval, -> { where("flags & 1 = 0") } # Not approved

  # Add a scope for experiences configured to federate using FlagShihTzu
  scope :federating, -> { where("flags & 2 != 0") } # Check federate flag (bit position 2)

  # Add a scope for offline-available experiences using FlagShihTzu
  scope :offline_available, -> { where("flags & 8 != 0") } # Check offline_available flag (bit position 8)

  # Add a scope for online-only experiences using FlagShihTzu
  scope :online_only, -> { where("flags & 8 = 0") } # Not offline_available

  # Automatically mark experiences created by admins as approved
  before_validation :auto_approve_for_admin, on: :create

  # Schedule vectorization after creation and updates
  # Only trigger if key attributes changed or it's a new record to avoid redundant job enqueues
  after_commit :schedule_vectorization, on: %i[create update], if: :should_vectorize?

  friendly_id :slug_candidates, use: %i[slugged finders history]

  def assign_owner
    # Use Current.account set by Reflex or fallback to Rodauth
    self.account_id ||= Current.account&.id || nil
  end

  def auto_approve_for_admin(*)
    return unless account_id

    admin_account = Account.where(id: account_id).pick(:flags).to_i & 1
    self.flags |= 1 if admin_account == 1 # Set approved flag (bit position 1)
  end

  def html_file?
    html_file.attached?
  end

  def slug_candidates
    [
      :title,
      [ :title, SecureRandom.hex(3) ]
    ]
  end

  def should_generate_new_friendly_id?
    slug.blank? || will_save_change_to_title?
  end

  # Check if this experience needs vectorization
  def needs_vectorization?
    # Vectorize ALL experiences, regardless of approval status
    # This allows for better search and admin/moderator functionality

    # No vector exists
    return true unless experience_vector

    # Vector is outdated
    experience_vector.needs_regeneration?(self)
  end

  # Find similar experiences using vector search
  def find_similar(limit: 10)
    ExperienceSearchService.find_related(self, limit: limit)
  end

  private

  def content_moderation
    # Check if automoderation is enabled instance-wide (default to true for security)
    automoderation_enabled = InstanceSetting.get_with_fallback("automoderation_enabled", nil, "true") == "true"

    # Skip moderation if disabled by admin
    return unless automoderation_enabled

    violations_found = false
    all_violations = []

    # Check title
    if title.present?
      title_violations = ModerationService.get_violation_details(title)
      if title_violations.present?
        all_violations << { field: "title", content: title, violations: title_violations }
        errors.add(:title, "contains inappropriate content and cannot be saved")
        violations_found = true
      end
    end

    # Check description
    if description.present?
      description_violations = ModerationService.get_violation_details(description)
      if description_violations.present?
        all_violations << { field: "description", content: description, violations: description_violations }
        errors.add(:description, "contains inappropriate content and cannot be saved")
        violations_found = true
      end
    end

    # Check author
    if author.present?
      author_violations = ModerationService.get_violation_details(author)
      if author_violations.present?
        all_violations << { field: "author", content: author, violations: author_violations }
        errors.add(:author, "contains inappropriate content and cannot be saved")
        violations_found = true
      end
    end

    # Log a single violation entry if any violations were found
    return unless violations_found

    log_moderation_violations(all_violations)
  end

  def log_moderation_violations(all_violations)
    # Use the first violation's field and content for the primary log entry
    primary_violation = all_violations.first

    # Combine all violation details
    all_violation_details = all_violations.flat_map { |v| v[:violations] || [] }

    # Create a comprehensive reason
    reason = if all_violation_details.empty?
      "content flagged by comprehensive moderation system"
    else
      all_violation_details.map { |v| "#{v[:type]}#{v[:details] ? " (#{v[:details].join(', ')})" : ''}" }.join("; ")
    end

    ModerationLog.log_rejection(
      field: primary_violation[:field],
      model_type: self.class.name,
      content: primary_violation[:content],
      reason: reason,
      account: account || Current.account,
      violations: all_violation_details
    )
  rescue StandardError => e
    Rails.logger.error "Failed to log moderation violation: #{e.message}"
  end

  # Determine if this experience should be vectorized
  def should_vectorize?
    # Vectorize ALL experiences for comprehensive search functionality

    # No vector exists - always needs vectorization
    return true unless experience_vector

    # Check if content has changed since last vectorization using persisted attributes
    # This works in async jobs unlike saved_change_to_*? methods
    experience_vector.needs_regeneration?(self)
  end

  # Schedule vectorization job
  def schedule_vectorization
    if Rails.env.development?
      # Run synchronously in development for immediate vector search
      VectorizeExperienceJob.perform_now(id)
    else
      # Run asynchronously in production
      VectorizeExperienceJob.perform_later(id)
    end
  rescue StandardError => e
    Rails.logger.error "Failed to schedule vectorization for experience #{id}: #{e.message}"
  end

  def force_utf8_encoding
    %i[title description author].each do |attr|
      val = self[attr]
      next unless val.is_a?(String)

      next if val.encoding == Encoding::UTF_8 && val.valid_encoding?

      begin
        coerced = val.dup.force_encoding(Encoding::UTF_8)
        coerced = coerced.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: "") unless coerced.valid_encoding?
        self[attr] = coerced
      rescue StandardError
        self[attr] = val.to_s.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: "")
      end
    end
  end
end
