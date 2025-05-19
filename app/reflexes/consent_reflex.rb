# frozen_string_literal: true

class ConsentReflex < ApplicationReflex
  # Accept consent: set cookies and redirect
  def accept(remember_opt_in = nil)
    # Set secure cookie with all recommended settings
    cookies.signed[EEAMode::CONSENT_COOKIE_KEY] = {
      value: "1",
      expires: EEAMode::COMPLIANCE[:cookie_settings][:expiration].from_now,
      same_site: EEAMode::COMPLIANCE[:cookie_settings][:same_site],
      secure: if EEAMode::COMPLIANCE[:cookie_settings][:secure].is_a?(Proc)
        EEAMode::COMPLIANCE[:cookie_settings][:secure].call
              else
        EEAMode::COMPLIANCE[:cookie_settings][:secure]
              end,
      httponly: EEAMode::COMPLIANCE[:cookie_settings][:httponly]
    }

    log_info("[EEA Compliance] Consent accepted for user with IP: #{request.remote_ip}")

    if remember_opt_in == "1"
      cookies.signed[:remember_opt_in] = {
        value: "1",
        expires: 30.days.from_now,
        same_site: :strict,
        secure: Rails.application.config.force_ssl,
        httponly: true
      }
    else
      cookies.delete(:remember_opt_in)
    end

    # Redirect to return_to or root
    return_to = session.delete(:return_to) || root_path
    cable_ready.redirect_to(url: return_to).broadcast
    morph :nothing
  end

  # Decline consent: show decline message
  def decline
    log_warn("[EEA Compliance] Consent declined for user with IP: #{request.remote_ip}")
    html = <<~HTML
      <div class="consent-decline">
        <h1>Consent Required</h1>
        <p>You declined the Privacy &amp; Cookie Policy. Libreverse cannot operate without the strictly necessary cookies described in the policy. Please reconsider to continue.</p>
        <button class="btn-secondary" data-action="click->consent#showScreen">Go Back</button>
      </div>
    HTML
    morph ".consent-overlay", html
  end

  # Optional: show the consent screen again (for Go Back)
  def show_screen
    html = controller.render_to_string(template: "consent/screen", layout: false)
    morph ".consent-overlay", html
  end
end
