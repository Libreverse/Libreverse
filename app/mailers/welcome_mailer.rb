# Example mailer demonstrating CSS inlining for emails
class WelcomeMailer < ApplicationMailer
  include EmailHelper

  def welcome_email(user)
    @user = user
    @inlined_css = inline_email_css("~/stylesheets/emails.scss")

    mail(
      to: @user.email,
      subject: "Welcome to Libreverse!"
    )
  end

  def newsletter(user, articles)
    @user = user
    @articles = articles

    # Use specific newsletter styles
    @newsletter_css = inline_vite_stylesheet("newsletter.scss")
    @base_css = inline_email_css("~/stylesheets/emails.scss")

    mail(
      to: @user.email,
      subject: "Weekly Newsletter - #{Date.current.strftime('%B %d, %Y')}"
    )
  end

  def password_reset(user, token)
    @user = user
    @token = token
    @reset_url = reset_password_url(token: @token)

    # Simple inline styling for security emails
    @inlined_css = inline_email_css("~/stylesheets/emails.scss")

    mail(
      to: @user.email,
      subject: "Reset Your Password"
    )
  end
end
