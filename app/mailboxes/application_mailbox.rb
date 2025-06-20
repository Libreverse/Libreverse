# frozen_string_literal: true

class ApplicationMailbox < ActionMailbox::Base
  # Route emails to appropriate mailboxes
  # Route search emails
  routing(/search@/i => :search)

  # Route experience download emails
  routing(/experiences@/i => :experiences)

  # Catch-all for unmatched emails
  routing all: :catch_all
end
