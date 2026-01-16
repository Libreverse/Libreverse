# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

Rails.application.reloader.to_prepare do
  # Patch all relevant ActiveStorage controllers to set strict private download headers
  [
    defined?(ActiveStorage::Blobs::ProxyController) && ActiveStorage::Blobs::ProxyController,
    defined?(ActiveStorage::Blobs::RedirectController) && ActiveStorage::Blobs::RedirectController,
    defined?(ActiveStorage::Representations::ProxyController) && ActiveStorage::Representations::ProxyController,
    defined?(ActiveStorage::Representations::RedirectController) && ActiveStorage::Representations::RedirectController,
    defined?(ActiveStorage::DiskController) && ActiveStorage::DiskController
  ].compact.each do |controller|
    controller.class_eval do
      actions = %i[show download].select { |a| action_methods.include?(a.to_s) }
      after_action only: actions do
        response.headers["Cache-Control"] = "private, max-age=0"
      end
    end
  end
end

# Active storage validations stubs

module ActiveStorageValidations
  # Only define stubs if the real gem hasn't been loaded
  module Model; end unless const_defined?(:Model)
  
  class BaseComparisonValidator < ActiveModel::EachValidator
  end unless const_defined?(:BaseComparisonValidator)

  unless const_defined?(:ContentTypeValidator)
    class ContentTypeValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, _value); end
    end
  end

  unless const_defined?(:SizeValidator)
    class SizeValidator < ActiveStorageValidations::BaseComparisonValidator
      def validate_each(record, attribute, _value); end
    end
  end

  unless const_defined?(:FilenameValidator)
    class FilenameValidator < ActiveModel::EachValidator
      def validate_each(*); end
    end
  end
end

# Map top-level constants only if not already defined
ContentTypeValidator = ActiveStorageValidations::ContentTypeValidator unless defined?(ContentTypeValidator)
SizeValidator        = ActiveStorageValidations::SizeValidator        unless defined?(SizeValidator)
FilenameValidator    = ActiveStorageValidations::FilenameValidator    unless defined?(FilenameValidator)

# Add lockbox to encrypt active storage blobs

derived_key = ActiveSupport::KeyGenerator.new(
  Rails.application.secret_key_base, iterations: 1000
).generate_key("lockbox", 32) # 32 raw bytes

Lockbox.master_key = derived_key.unpack1("H*") # convert to hex
