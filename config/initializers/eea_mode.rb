# frozen_string_literal: true

# EEA Mode Initializer
# --------------------
# This file enables "EEA mode" (additional GDPR/ePrivacy safeguards) when the
# option `eea_mode` in the top‑level `libreverse.ini` configuration file is not
# explicitly disabled.
#
# Key responsibilities:
#   • Parse `libreverse.ini` once at boot. (Lightweight manual parser to avoid
#     adding the `inifile` gem.)
#   • Provide `EEAMode.enabled?` query method.
#   • Inject a `before_action` in every controller (HTML requests only) that
#     blocks the response until the user has provided the required privacy
#     consent.  If consent is missing, we render the full‑screen consent view
#     located at `app/views/consent/screen.html.erb` (to be created).
#   • Expose `consent_given?` helper so views/layouts can react (e.g. hide
#     banner once consent stored).
#
# NOTE:  The heavy UI pieces (view, stimulus controller, CSS) will be added in
#        subsequent commits.  This initializer lays the foundation so the rest
#        of the application can query `EEAMode.enabled?` and the request‑level
#        helper.

module EEAMode
  CONFIG_PATH = Rails.root.join("libreverse.ini")

  # Return true if EEA mode should be active.
  # Default:  true (fail‑secure) unless the ini sets `eea_mode = false`.
  def self.enabled?
    return @enabled unless @enabled.nil?

    # If the config file does not exist, default to enabled (fail‑secure).
    unless CONFIG_PATH.exist?
      @enabled = true
      return @enabled
    end

    raw = File.read(CONFIG_PATH)

    @enabled = if raw =~ /^\s*eea_mode\s*=\s*(\w+)/i
                 value = Regexp.last_match(1).downcase
                 !(%w[false 0 no off].include?(value))
               else
                 true
               end
  end

  # Cookie key used to remember that the user has accepted privacy/cookie terms.
  CONSENT_COOKIE_KEY = :privacy_consent

  # ---------------------------------------------------------------------------
  # Controller concern injected into `ActionController::Base`.
  # ---------------------------------------------------------------------------
  module ConsentEnforcer
    extend ActiveSupport::Concern

    included do
      before_action :_enforce_privacy_consent, if: -> { EEAMode.enabled? }
      helper_method :consent_given?
    end

    private

    # Returns true if the signed consent cookie has been stored.
    def consent_given?
      cookies.signed[EEAMode::CONSENT_COOKIE_KEY] == "1"
    end

    # Determines whether the current request path is exempt from the consent
    # check (e.g. the privacy policy itself or static assets).
    def consent_exempt_path?
      path = request.path

      return true if path.start_with?("/privacy", "/cookies")
      return true if path.start_with?("/assets", "/packs", "/vite")
      return true if path.start_with?("/rails/active_storage")
      return true if path.start_with?("/cable")
      return true if path.start_with?("/up") # health check
      return true if path.start_with?("/consent") # future dedicated route

      false
    end

    # Main guard.  For non‑HTML requests we simply continue to avoid breaking
    # APIs; JSON/XMLRPC endpoints are already authenticated.  You may want to
    # extend this behaviour later.
    def _enforce_privacy_consent
      return if consent_given? || consent_exempt_path? || !request.format.html?

      # Render the full‑screen consent page without redirecting so that the URL
      # doesn't change unexpectedly.  We deliberately avoid using `layout:
      # false` to inherit the application layout (CSS/JS availability), but the
      # view should visually cover the whole viewport.
      render template: "consent/screen", layout: "application", status: :ok
    end
  end
end

# Hook the concern into all controllers automatically.
ActiveSupport.on_load(:action_controller_base) do
  include EEAMode::ConsentEnforcer
end

# -----------------------------------------------------------------------------
# Runtime additions: Consent controller + routes
# -----------------------------------------------------------------------------

# Remove eager controller definitions to avoid ApplicationController missing

Rails.application.config.to_prepare do
  # Define Consent controller lazily after ApplicationController is loaded
  unless defined?(ConsentsController)
    class ConsentsController < ApplicationController
      skip_before_action :_enforce_privacy_consent

      layout "application"

      # GET /consent (rendered automatically by interceptor but also routable)
      def show
        session[:return_to] ||= params[:return_to] || request.referer || root_path
        render template: "consent/screen", layout: "application"
      end

      # POST /consent/accept
      def accept
        cookies.signed[EEAMode::CONSENT_COOKIE_KEY] = {
          value: "1",
          expires: 1.year.from_now,
          same_site: :strict,
          secure: Rails.env.production?,
          httponly: true
        }

        if params[:remember_opt_in] == "1"
          cookies.signed[:remember_opt_in] = {
            value: "1",
            expires: 30.days.from_now,
            same_site: :strict,
            secure: Rails.env.production?,
            httponly: true
          }
        else
          cookies.delete(:remember_opt_in)
        end

        redirect_to(session.delete(:return_to) || root_path)
      end

      # POST /consent/decline
      def decline
        render inline: <<~ERB, status: :ok
          <div class="consent-decline">
            <h1>Consent Required</h1>
            <p>You declined the Privacy &amp; Cookie Policy. Libreverse cannot operate without the strictly necessary cookies described in the policy. Please reconsider to continue.</p>
            <%= button_to "Go Back", consent_path, method: :get, class: "btn-secondary" %>
          </div>
        ERB
      end
    end
  end

  # Define Policies controller lazily as well
  unless defined?(PoliciesController)
    class PoliciesController < ApplicationController
      skip_before_action :_enforce_privacy_consent

      layout "application"

      DISCLAIMER = <<~HTML.freeze
        <p class="policy-disclaimer">
          This Privacy Policy and Cookie Policy are provided in English due to resource constraints.
        </p>
      HTML

      def privacy
        render inline: <<~ERB
          <h1>Privacy Policy</h1>
          #{DISCLAIMER}
          <p>Libreverse stores only the data necessary to operate the service: account credentials, optional preferences, and any content you upload ("experiences"). We never sell your data and we do not use third‑party trackers or analytics.</p>
          <h2>Lawful basis</h2>
          <p>Your data is processed on the basis of contract (to provide the service) and, where applicable, consent (optional cookies).</p>
          <h2>Your rights</h2>
          <ul>
            <li>Access, rectification, deletion</li>
            <li>Portability &amp; restriction</li>
            <li>Objection and complaint to your local DPA</li>
          </ul>
          <p>Contact <a href="mailto:support@libreverse.dev">support@libreverse.dev</a> to exercise your rights.</p>
        ERB
      end

      def cookies
        render inline: <<~ERB
          <h1>Cookie Policy</h1>
          #{DISCLAIMER}
          <p>Libreverse uses strictly necessary cookies for session security ("_libreverse_session") and an optional remember‑me cookie ("remember_*") which persists your login for 30 days.</p>
          <p>The remember‑me cookie is only set if you enable it on the consent screen.</p>
        ERB
      end
    end
  end
end

Rails.application.routes.append do
  scope "/" do
    get  "consent",          to: "consents#show",   as: :consent
    post "consent/accept",   to: "consents#accept",  as: :consent_accept
    post "consent/decline",  to: "consents#decline", as: :consent_decline

    # -----------------------------------------------------------------------
    # Policies (Privacy & Cookies)
    # -----------------------------------------------------------------------
    get "privacy", to: "policies#privacy",  as: :privacy_policy
    get "cookies", to: "policies#cookies",  as: :cookie_policy
  end
end 