# frozen_string_literal: true
# shareable_constant_value: literal

# JIT Warmup Service for TruffleRuby
#
# Pre-warms the JIT compiler by exercising common code paths for public/logged-out routes.
# This reduces latency for the first real requests by ensuring hot code paths are compiled.
#
# TruffleRuby JIT compiles METHODS, not object instances. Once a method like
# `Account#guest?` or `ApplicationController#current_account` is compiled,
# it stays compiled for ALL future calls regardless of which account/session is used.
#
# The warmup uses a persistent session to simulate a real guest user browsing multiple pages,
# which properly exercises the rodauth-guest code paths that create and maintain guest sessions.
#
# Usage:
#   JitWarmupService.warmup           # Run full warmup
#   JitWarmupService.warmup(runs: 5)  # Custom number of iterations
#
class JitWarmupService
  # Public routes visible to logged-out users (from sidebar)
  PUBLIC_PATHS = [
    "/",           # Homepage
    "/search",     # Search page
    "/forum",      # Forum
    "/lm",         # LibreverseLM
    "/blog",       # Blog
    "/map",        # Map page
    "/settings"    # Settings page
  ].freeze

  # Additional public routes for logged-out users (from sidebar)
  GUEST_PATHS = [
    "/dashboard",           # Dashboard (limited view for guests)
    "/experiences",         # Experiences page (for guests)
    "/login",               # Login page (Rodauth)
    "/create-account"       # Sign-up page (Rodauth)
  ].freeze

  # Static/utility routes worth warming (minimal set that exercises controller code)
  # Note: /robots.txt, /sitemap.xml are static-ish and don't benefit much from JIT warmup
  # Policy pages (/terms, /privacy, /cookies) are simple renders
  UTILITY_PATHS = [].freeze

  # Routes to skip (handled by engines or require auth)
  SKIP_PATTERNS = [
    %r{^/rails/},
    %r{^/assets/},
    %r{^/cable},
    %r{^/admin/},
    %r{^/cms-admin}
  ].freeze

  class << self
    # Perform JIT warmup with configurable iterations
    #
    # @param runs [Integer] Number of times to exercise each route (default: 3)
    # @param paths [Array<String>] Custom paths to warm (default: all public paths)
    # @param silent [Boolean] Suppress output (default: false in development)
    # @return [Hash] Statistics about the warmup run
    def warmup(runs: default_runs, paths: all_warmup_paths, silent: !Rails.env.development?)
      return skip_warmup_result unless should_warmup?

      # Step 1: Prime internal caches and helpers
      prime_internal_caches(silent: silent)

      require "rack/mock"

      stats = { paths: 0, requests: 0, errors: 0, skipped: 0, duration_ms: 0, guest_accounts_created: 0 }
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      app = Rails.application

      # Use Rack::MockRequest directly on the app
      # We'll manually track cookies to maintain session across requests
      mock = Rack::MockRequest.new(app)
      cookies = {}

      log_start(paths.size, runs) unless silent

      # Track guest accounts before warmup
      guest_count_before = count_guest_accounts

      paths.each do |path|
        if skip_path?(path)
          stats[:skipped] += 1
          next
        end

        unless route_available?(path)
          stats[:skipped] += 1
          log_missing_route(path) unless silent
          next
        end

        stats[:paths] += 1

        runs.times do
            # Build cookie header from stored cookies
            cookie_header = cookies.map { |k, v| "#{k}=#{v}" }.join("; ")

            response = mock.get(
              path,
              "HTTP_HOST" => warmup_host,
              "HTTPS" => "on",
              "HTTP_USER_AGENT" => "JitWarmup/1.0",
              "HTTP_ACCEPT" => "text/html,application/xhtml+xml",
              "HTTP_COOKIE" => cookie_header,
              # Mark as internal warmup request
              "HTTP_X_JIT_WARMUP" => "1"
            )
            stats[:requests] += 1

            # Extract and store cookies from response for session persistence
            extract_cookies(response, cookies)

            # Log non-success responses in verbose mode
            log_response_issue(path, response.status) unless silent || (200..399).cover?(response.status)
        rescue StandardError => e
            stats[:errors] += 1
            log_error(path, e) unless silent
        end
      end

      # Track guest accounts created during warmup
      stats[:guest_accounts_created] = count_guest_accounts - guest_count_before

      # Log cleanup note
      cleanup_warmup_guest unless silent

      stats[:duration_ms] = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).round(2)

      log_complete(stats) unless silent
      stats
    end

    # All paths to warm up
    def all_warmup_paths
      PUBLIC_PATHS + GUEST_PATHS + UTILITY_PATHS
    end

    # Check if current request is a warmup request
    def warmup_request?(request)
      request.headers["HTTP_X_JIT_WARMUP"] == "1" ||
        request.user_agent&.start_with?("JitWarmup/")
    end

    private

    # Prime internal caches that affect request performance
    def prime_internal_caches(silent: false)
      Rails.logger.debug("[JitWarmup] Priming internal caches...") unless silent

      # Prime route recognition
      prime_routes

      # Prime view helpers compilation
      prime_view_helpers

      # Prime model attribute methods
      prime_model_methods

      # Prime I18n translations
      prime_i18n

      Rails.logger.debug("[JitWarmup] Cache priming complete") unless silent
    rescue StandardError => e
      Rails.logger.debug("[JitWarmup] Cache priming error (non-fatal): #{e.message}")
    end

    def prime_routes
      # Force route set compilation
      Rails.application.routes.recognize_path("/")
      Rails.application.routes.recognize_path("/search")
      Rails.application.routes.recognize_path("/dashboard")
    rescue ActionController::RoutingError
      # Expected for some paths
    end

    def prime_view_helpers
      # Force helper method compilation by accessing common helpers
      return unless defined?(ApplicationController)

      # Create a dummy view context to prime helpers
      controller = ApplicationController.new
      return unless controller.respond_to?(:view_context, true)

      ctx = controller.send(:view_context)

      # Prime commonly used helpers
      ctx.link_to("test", "/") if ctx.respond_to?(:link_to)
      ctx.content_tag(:div, "test") if ctx.respond_to?(:content_tag)
      ctx.image_tag("test.png") if ctx.respond_to?(:image_tag)
    rescue StandardError
      # Helpers may fail without full request context, that's OK
    end

    def prime_model_methods
      # Force ActiveRecord to generate attribute methods
      return unless defined?(Account)

      # Touch models to generate attribute accessors
      [ Account, Experience, UserPreference ].each do |model|
        model.define_attribute_methods if model.respond_to?(:define_attribute_methods)
      rescue StandardError
        # Model may not exist or have issues
      end
    end

    def prime_i18n
      # Force I18n backend to load translations
      I18n.t("activerecord.models.account", default: "Account")
      I18n.t("helpers.submit.create", default: "Create")
    rescue StandardError
      # I18n may not be fully configured
    end

    def should_warmup?
      # Only warmup on TruffleRuby or when forced
      return true if ENV["FORCE_JIT_WARMUP"] == "1"
      return true if RUBY_ENGINE == "truffleruby"

      Rails.logger.info("[JitWarmup] Skipping warmup - not running on TruffleRuby")
      false
    end

    def skip_warmup_result
      { paths: 0, requests: 0, errors: 0, skipped: 0, duration_ms: 0, skipped_reason: "not_truffleruby" }
    end

    def skip_path?(path)
      SKIP_PATTERNS.any? { |pattern| pattern.match?(path) }
    end

    def route_available?(path)
      # Simple route check - just verify the path resolves to a controller/action
      Rails.application.routes.recognize_path(path, method: :get)
      true
    rescue ActionController::RoutingError, ActionController::UrlGenerationError
      false
    rescue StandardError
      false
    end

    def default_runs
      # Always do one run per path for faster warmup
      1
    end

    def warmup_host
      ENV.fetch("JIT_WARMUP_HOST", "localhost:3000")
    end

    def count_guest_accounts
      return 0 unless defined?(Account)

      Account.where(guest: true).count
    rescue StandardError
      0
    end

    # Extract cookies from response and merge into cookie jar
    def extract_cookies(response, cookies)
      return unless response.respond_to?(:headers)

      set_cookie = response.headers["Set-Cookie"]
      return unless set_cookie

      # Handle both single cookie and multiple cookies
      cookie_strings = set_cookie.is_a?(Array) ? set_cookie : [ set_cookie ]

      cookie_strings.each do |cookie_str|
        next unless cookie_str

        # Parse cookie name=value (ignore attributes like path, expires, etc.)
        next unless (match = cookie_str.match(/\A([^=]+)=([^;]*)/))

        name = match[1]
        value = match[2]
        cookies[name] = value
      end
    rescue StandardError
      # Cookie extraction failed, continue without session persistence
    end

    def cleanup_warmup_guest
      # Best-effort cleanup - rely on the guest cleanup job to handle orphaned warmup guests
      return unless defined?(Account)

      Rails.logger.debug("[JitWarmup] Warmup guest account will be cleaned up by scheduled job")
    rescue StandardError => e
      Rails.logger.debug("[JitWarmup] Guest cleanup skipped: #{e.message}")
    end

    def log_start(path_count, runs)
      Rails.logger.info("[JitWarmup] Starting warmup: #{path_count} paths × #{runs} runs (with persistent session)")
    end

    def log_complete(stats)
      guest_info = stats[:guest_accounts_created].positive? ? " (#{stats[:guest_accounts_created]} guest accounts)" : ""
      Rails.logger.info(
        "[JitWarmup] Complete: #{stats[:requests]} requests across #{stats[:paths]} paths " \
        "in #{stats[:duration_ms]}ms (#{stats[:errors]} errors, #{stats[:skipped]} skipped)#{guest_info}"
      )
    end

    def log_response_issue(path, status)
      Rails.logger.debug("[JitWarmup] #{path} returned #{status}")
    end

    def log_missing_route(path)
      Rails.logger.debug("[JitWarmup] Skipping #{path} (no matching route for warmup)")
    end

    def log_error(path, error)
      Rails.logger.warn("[JitWarmup] Error on #{path}: #{error.class}: #{error.message}")
    end
  end
end
