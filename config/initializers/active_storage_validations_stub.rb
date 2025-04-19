# frozen_string_literal: true

module ActiveStorageValidations
  # Only define stubs if the real gem hasn't been loaded
  module Model; end unless const_defined?(:Model)

  unless const_defined?(:ContentTypeValidator)
    class ContentTypeValidator < ActiveModel::EachValidator
      def validate_each(*); end
    end
  end

  unless const_defined?(:SizeValidator)
    class SizeValidator < ActiveModel::EachValidator
      def validate_each(*); end
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
