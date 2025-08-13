module Federails::Moderation
  module FilteredInbox
    extend ActiveSupport::Concern

    included do
      class <<self
        def filter_request(payload)
          filtered_dispatch_request(payload) unless
            (payload["id"] && DomainBlock.blocked?(URI.parse(payload["id"]).host)) ||
            (payload["actor"] && DomainBlock.blocked?(URI.parse(payload["actor"]).host))
        end

        alias_method :filtered_dispatch_request, :dispatch_request
        alias_method :dispatch_request, :filter_request
      end
    end
  end
end
