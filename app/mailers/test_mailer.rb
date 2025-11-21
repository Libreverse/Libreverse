# frozen_string_literal: true
# shareable_constant_value: literal

class TestMailer < ApplicationMailer
  def test_email(to_email = "test@example.com")
    @message = "This is a test email from LibreVerse!"
    @timestamp = Time.current

    mail(
      to: to_email,
      subject: "LibreVerse Email Test",
      template_name: "test_email"
    )
  end
end
