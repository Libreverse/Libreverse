require "public_suffix"

module Federails::Moderation
  class DomainNameValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      record.errors.add attribute, :invalid unless PublicSuffix.valid?(value, default_rule: nil)
    end
  end
end
