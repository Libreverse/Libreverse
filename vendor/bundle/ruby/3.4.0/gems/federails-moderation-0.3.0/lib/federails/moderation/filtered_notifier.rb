module Federails::Moderation
  module FilteredNotifier
    extend ActiveSupport::Concern

    included do
      class <<self
        def filter_post_to_inbox(to:, message:, from: nil)
          filtered_post_to_inbox(to: to, message: message, from: from) unless DomainBlock.blocked?(to.server)
        end

        alias_method :filtered_post_to_inbox, :post_to_inbox
        alias_method :post_to_inbox, :filter_post_to_inbox
      end
    end
  end
end
