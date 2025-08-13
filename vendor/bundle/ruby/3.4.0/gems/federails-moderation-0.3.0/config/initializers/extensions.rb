require "fediverse/inbox"
require "federails/moderation/filtered_inbox"

Fediverse::Inbox.send(:include, Federails::Moderation::FilteredInbox)

require "fediverse/notifier"
require "federails/moderation/filtered_notifier"

Fediverse::Notifier.send(:include, Federails::Moderation::FilteredNotifier)
