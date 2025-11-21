# frozen_string_literal: true
# shareable_constant_value: literal

class CatchAllMailbox < ApplicationMailbox
  def process
    # Log unmatched emails
    Rails.logger.info "Received unmatched email from #{mail.from.first} to #{mail.to.first}"
    Rails.logger.info "Subject: #{mail.subject}"

    # For now, just ignore unmatched emails
    # In production, you might want to forward to an admin or send an auto-reply
  end
end
