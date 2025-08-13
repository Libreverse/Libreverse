module Federails::Moderation
  class DomainBlock < ApplicationRecord
    validates :domain, presence: true, uniqueness: true, "federails/moderation/domain_name": true

    def self.blocked?(query)
      self.exists?(domain: [ query, PublicSuffix.parse(query).domain ])
    end
  end
end
