# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

Rails.application.config.to_prepare do
  if defined?(ActionMailbox::InboundEmail)
    ActionMailbox::InboundEmail.class_eval do
      validates :message_checksum, :message_id, :status, presence: true
      validates :message_checksum, :message_id, length: { maximum: 255 }, allow_blank: true
    end
  end

  if defined?(ActionText::RichText)
    ActionText::RichText.class_eval do
      validates :name, presence: true
      validates :name, :record_type, length: { maximum: 255 }, allow_blank: true
      validates :body, length: { maximum: 4_294_967_295 }, allow_blank: true
    end
  end

  if defined?(ActionText::EncryptedRichText)
    ActionText::EncryptedRichText.class_eval do
      validates :name, presence: true
      validates :name, :record_type, length: { maximum: 255 }, allow_blank: true
      validates :body, length: { maximum: 4_294_967_295 }, allow_blank: true
    end
  end

  if defined?(ActiveStorage::Attachment)
    ActiveStorage::Attachment.class_eval do
      validates :name, presence: true
      validates :name, :record_type, length: { maximum: 255 }, allow_blank: true
    end
  end

  if defined?(ActiveStorage::Blob)
    ActiveStorage::Blob.class_eval do
      validates :byte_size, :filename, :key, presence: true
      validates :checksum, :content_type, :filename, :key, :service_name,
                length: { maximum: 255 }, allow_blank: true
      validates :metadata, length: { maximum: 65_535 }, allow_blank: true
    end
  end

  if defined?(ActiveStorage::VariantRecord)
    ActiveStorage::VariantRecord.class_eval do
      validates :variation_digest, presence: true
      validates :variation_digest, length: { maximum: 255 }
    end
  end
end
