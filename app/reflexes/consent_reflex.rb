# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

class ConsentReflex < ApplicationReflex
  def accept
    dataset = element.dataset || {}

    # dataset keys originate from HTML data-* (kebab-case -> camelCase)
    remember_opt_in_raw = dataset["rememberOptIn"] || dataset["remember_opt_in"]
    remember_opt_in = remember_opt_in_raw.to_s == "true"

    cookie_settings = EEAMode.compliance[:cookie_settings]
    # Modern browsers reject `SameSite=None` cookies unless `Secure` is also set.
    # This app intentionally uses `SameSite=None` for Electron/iframes, so ensure
    # Secure is enabled when the request is HTTPS or the desktop UA is present.
    user_agent = request&.user_agent.to_s
    secure = cookie_settings[:secure] || request&.ssl? || user_agent.include?("LibreverseDesktopApp/")
    same_site = cookie_settings[:same_site]
    expires_at = cookie_settings[:expiration].from_now

    same_site_token =
      case same_site
      when :none then "None"
      when :lax then "Lax"
      when :strict then "Strict"
      else same_site.to_s
      end

    base = [
      "#{EEAMode::CONSENT_COOKIE_KEY}=1",
      "Path=/",
      "Expires=#{expires_at.utc.httpdate}",
      "SameSite=#{same_site_token}"
    ]
    base << "Secure" if secure
    base << "Partitioned" if secure && same_site_token == "None"

    # Broadcast is required for non-morph CableReady operations.
    # We chain both cookies + redirect into a single broadcast.
    cr = cable_ready.set_cookie(cookie: base.join("; "))

    remember_cookie = [ "remember_opt_in=#{remember_opt_in ? 1 : nil}", "Path=/" ]

    if remember_opt_in
      remember_cookie << "Expires=#{30.days.from_now.utc.httpdate}"
      remember_cookie << "SameSite=#{same_site_token}"
      remember_cookie << "Secure" if secure
      remember_cookie << "Partitioned" if secure && same_site_token == "None"
    else
      # Expire cookie immediately
      remember_cookie[0] = "remember_opt_in="
      remember_cookie << "Expires=#{1.day.ago.utc.httpdate}"
    end

    cr = cr.set_cookie(cookie: remember_cookie.join("; "))

    Rails.logger.info("[EEA Compliance] Consent accepted via Reflex")

    return_to = session.delete(:return_to) || Rails.application.routes.url_helpers.root_path
    cr.redirect_to(url: return_to).broadcast
  end

  def decline
    # Log (server side)
    Rails.logger.warn("[EEA Compliance] Consent declined via Reflex")

    morph ".consent-overlay", ConsentDeclineComponent.new.call
  end
end
