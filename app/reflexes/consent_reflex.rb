# frozen_string_literal: true

class ConsentReflex < ApplicationReflex
  def accept
    remember_opt_in = element.dataset[:remember_opt_in] == "true"
    
    # Set the consent cookie via CableReady (requires httponly: false)
    cable_ready.set_cookie(
      name: EEAMode::CONSENT_COOKIE_KEY,
      value: "1",
      expires: 1.year.from_now,
      path: "/",
      same_site: "Strict",
      secure: Rails.application.config.force_ssl
    )

    if remember_opt_in
      cable_ready.set_cookie(
        name: "remember_opt_in",
        value: "1",
        expires: 30.days.from_now,
        path: "/",
        same_site: "Strict",
        secure: Rails.application.config.force_ssl
      )
    else
      cable_ready.set_cookie(
        name: "remember_opt_in",
        value: "",
        expires: 1.day.ago,
        path: "/"
      )
    end

    Rails.logger.info("[EEA Compliance] Consent accepted via Reflex")

    return_to = session.delete(:return_to) || root_path
    cable_ready.redirect_to(url: return_to)
  end

  def decline
    # Log (server side)
    Rails.logger.warn("[EEA Compliance] Consent declined via Reflex")

    html = <<~HTML
      <div class="consent-decline">
          <h1>Consent Required</h1>
          <p>You declined the Privacy &amp; Cookie Policy. Libreverse cannot operate without the strictly necessary cookies described in the policy. Please reconsider to continue.</p>
          <button class="btn-secondary" data-action="click->consent#showScreen">Go Back</button>
      </div>
    HTML

    morph ".consent-overlay", html
  end
end
