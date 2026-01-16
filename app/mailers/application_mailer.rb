# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

class ApplicationMailer < ActionMailer::Base
  include EmailHelper # Include email CSS inlining helper
  helper EmailHelper # Make EmailHelper methods available to mailer views

  default from: -> { LibreverseInstance.email_bot_address }
  layout "mailer"
end
