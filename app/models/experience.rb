# frozen_string_literal: true

require "active_storage_validations"

class Experience < ApplicationRecord
  include ActiveStorageValidations::Model
  include GraphqlRails::Model

  graphql do |c|
    c.attribute(:id, type: "ID!")
    c.attribute(:title, type: "String!")
    c.attribute(:description, type: "String")
    c.attribute(:author, type: "String")
    c.attribute(:approved, type: "Boolean!")
    c.attribute(:account_id, type: "ID")
    c.attribute(:html_file?, type: "Boolean!")
    c.attribute(:created_at, type: "String!")
    c.attribute(:updated_at, type: "String!")
  end

  belongs_to :account, optional: true
  has_one_attached :html_file, dependent: :purge_later
  encrypts_attached :html_file

  validates :title, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 2000 }
  validates :author, length: { maximum: 255 }
  validates :html_file, presence: true,
                        content_type: "text/html",
                        filename: {
                          with: /\A[\w.-]+\z/,
                          message: "only letters, numbers, underscores, dashes and periods are allowed in filenames"
                        }, unless: -> { Rails.env.test? }

  # Content moderation validation
  validate :content_moderation

  # Ensure content is sanitized before saving
  # before_save :sanitize_content

  # Ensure an owner is always associated
  before_validation :assign_owner, on: :create

  # Add a scope for approved experiences
  scope :approved, -> { where(approved: true) }

  # Add a scope for experiences pending approval
  scope :pending_approval, -> { where(approved: false) }

  # Automatically mark experiences created by admins as approved
  before_validation :auto_approve_for_admin, on: :create

  # private

  # def sanitize_content
  #   return unless content_changed?
  #
  #   # Rails' sanitize helper
  #   self.content = ActionController::Base.helpers.sanitize(
  #     content,
  #     tags: %w[p br h1 h2 h3 h4 h5 h6 ul ol li strong em b i u code pre blockquote],
  #     attributes: %w[class id]
  #   )
  # end

  def assign_owner
    # Use Current.account set by Reflex or fallback to Rodauth
    self.account_id ||= Current.account&.id || nil
  end

  def auto_approve_for_admin
    self.approved = true if account&.admin?
  end

  def html_file?
    html_file.attached?
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
end
