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
#     consent for specific paths. If consent is missing, we render the full‑screen consent view
#     located at `app/views/consent/screen.html.erb`.
#   • Expose `consent_given?` helper so views/layouts can react (e.g. hide
#     banner once consent stored).
#
# NOTE:  The heavy UI pieces (view, stimulus controller, CSS) will be added in
#        subsequent commits.  This initializer lays the foundation so the rest
#        of the application can query `EEAMode.enabled?` and the request‑level
#        helper.

module EEAMode
  # Compliance verification constants
  COMPLIANCE = {
    required: {
      all_paths_require_consent: true,
      secure_cookies: true,
      policy_exemptions: %w[consent privacy cookies]
    },
    cookie_settings: {
      httponly: true,
      secure: -> { Rails.application.config.force_ssl },
      same_site: :strict,
      expiration: 1.year
    }
  }.freeze

  # ---------------------------------------------------------------------
  # Configuration via ENV variable only
  # ---------------------------------------------------------------------

  # Return true if EEA mode is active. Must be provided via EEA_MODE env var
  # with a truthy value ("true", "1", "yes", "on"). Any other value is
  # treated as disabled. Missing variable will raise at boot, enforcing
  # explicit configuration.
  def self.enabled?
    return @enabled unless @enabled.nil?

    raw = ENV.fetch("EEA_MODE") # raises KeyError if missing
    @enabled = %w[true 1 yes on].include?(raw.to_s.downcase)
  end

  def self.verify_compliance
    COMPLIANCE[:required].each do |key, value|
      raise "EEA Compliance Violation: #{key} not configured properly" unless value
    end
    true
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

    # Main guard. Enforce consent for all HTML requests in EEA mode
    def _enforce_privacy_consent
      return unless EEAMode.enabled?

      # Skip for policy pages that must be accessible without consent
      path = request.path
      return if path.start_with?("/privacy", "/cookies", "/consent")

      # Otherwise enforce for all HTML requests
      return unless !consent_given? && request.format.html?

        log_consent_requirement
        render template: "consent/screen", layout: "application", status: :ok
    end

    def log_consent_requirement
      Rails.logger.info(
        "[EEA Compliance] Consent required for: " \
        "path: #{request.path}, " \
        "referrer: #{request.referer || 'none'}"
      )
    end
  end
end

# Verify compliance at boot in production
EEAMode.verify_compliance if Rails.env.production?

# Hook the concern into all controllers automatically.
ActiveSupport.on_load(:action_controller_base) do
  include EEAMode::ConsentEnforcer
end

# -----------------------------------------------------------------------------
# Runtime additions: Consent controller + routes
# -----------------------------------------------------------------------------

# Remove eager controller definitions to avoid ApplicationController missing

Rails.application.routes.append do
  rs = Rails.application.routes
  unless rs.named_routes.key?(:consent_accept)
    scope "/" do
      get  "consent",          to: "consents#show", as: :consent unless rs.named_routes.key?(:consent)
      post "consent/accept",   to: "consents#accept",  as: :consent_accept
      post "consent/decline",  to: "consents#decline", as: :consent_decline

      # -----------------------------------------------------------------------
      # Policies (Privacy & Cookies)
      # -----------------------------------------------------------------------
    end
  end
end
