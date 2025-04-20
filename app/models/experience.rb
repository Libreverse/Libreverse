# frozen_string_literal: true

require "active_storage_validations"

class Experience < ApplicationRecord
  include ActiveStorageValidations::Model

  belongs_to :account, optional: true
  has_one_attached :html_file, dependent: :purge_later

  validates :title, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 2000 }
  validates :author, length: { maximum: 255 }
  validates :html_file, presence: true,
                        content_type: "text/html",
                        size: { less_than: 5.megabytes, message: "file must be less than 5MB" },
                        filename: {
                          with: /\A[\w.-]+\z/,
                          message: "only letters, numbers, underscores, dashes and periods are allowed in filenames"
                        }

  # Ensure content is sanitized before saving
  # before_save :sanitize_content

  # Ensure an owner is always associated
  before_validation :assign_owner, on: :create

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
end
