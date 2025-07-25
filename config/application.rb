# frozen_string_literal: true

require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Load custom middleware
require_relative "../lib/middleware/whitespace_compressor"
require_relative "../lib/middleware/zstd"
require_relative "../lib/middleware/emoji_replacer"

# Configuration for the application, engines, and railties goes here.
#
# These settings can be overridden in specific environments using the files
# in config/environments, which are processed later.

# config.time_zone = "Central Time (US & Canada)"

module LibreverseInstance
  class Application < Rails::Application
    config.autoload_paths << "app/graphql"
    config.autoload_paths << "app/indexers"

    # Exclude gRPC files from autoloading and eager loading to avoid boot issues
    config.autoload_paths.delete("#{config.root}/app/grpc")
    config.eager_load_paths.delete("#{config.root}/app/grpc")

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks middleware haml_lint])

    # For some reason I don't really understand, it only works if defined here.
    # I would put it in an initializer, but it causes content encoding issues.

    # Zstandard compression middleware
    config.middleware.use Rack::Zstd,
                          window_log: 27,
                          chain_log: 27,
                          hash_log: 25,
                          search_log: 9,
                          min_match: 3,
                          strategy: :btultra2,
                          sync: false

    # Add WhitespaceCompressor middleware to minify HTML before compression
    config.middleware.use WhitespaceCompressor

    # Add EmojiReplacer middleware to process emoji replacement in HTML responses
    # Position it before WhitespaceCompressor to ensure emojis are replaced before minification
    config.middleware.insert_before WhitespaceCompressor, EmojiReplacer, {
      exclude_selectors: [
        "script", "style", "pre", "code", "textarea", "svg", "noscript", "template",
        ".no-emoji", "[data-no-emoji]", ".syntax-highlighted"
      ]
    }

    # Add this to make prod healthcheck pass correctly
    config.hosts << "localhost:3000"

    # I18n configuration
    config.i18n.default_locale = :en
    config.i18n.available_locales = %i[en zh es hi ar pt fr ru de ja]

    # I prefer this. It's just nicer, somehow.
    config.active_record.schema_format = :sql

    # Email bot configuration using Action Mailbox
    config.action_mailbox.ingress = :imap
    config.action_mailbox.logger = Rails.logger

    # Class method to get instance domain, delegating to module-level method
    def self.instance_domain
      LibreverseInstance.instance_domain
    end

    # Delegate all configuration methods to module-level methods
    def self.port
      LibreverseInstance.port
    end

    def self.admin_email
      LibreverseInstance.admin_email
    end

    def self.rails_log_level
      LibreverseInstance.rails_log_level
    end

    def self.cors_origins
      LibreverseInstance.cors_origins
    end

    def self.allowed_hosts
      LibreverseInstance.allowed_hosts
    end

    def self.force_ssl?
      LibreverseInstance.force_ssl?
    end

    def self.no_ssl?
      LibreverseInstance.no_ssl?
    end

    def self.eea_mode_enabled?
      LibreverseInstance.eea_mode_enabled?
    end

    def self.grpc_enabled?
      LibreverseInstance.grpc_enabled?
    end

    def self.email_bot_enabled?
      LibreverseInstance.email_bot_enabled?
    end

    def self.email_bot_address
      LibreverseInstance.email_bot_address
    end

    def self.email_bot_mail_host
      LibreverseInstance.email_bot_mail_host
    end

    def self.email_bot_username
      LibreverseInstance.email_bot_username
    end

    def self.email_bot_password
      LibreverseInstance.email_bot_password
    end

    # Delegate reset method to module
    def self.reset_all_cached_config!
      LibreverseInstance.reset_all_cached_config!
    end
  end

  # Simple configuration methods for early boot
  # Port, domain uses smart detection, others have sensible defaults

  def self.port
    return @port if defined?(@port)

    @port = if can_access_database?
      setting = InstanceSetting.find_by(key: "port")
      raw = setting&.value
 raise ArgumentError, "Invalid port: #{raw.inspect}" if raw.present? && raw !~ /^\d+$/

 raw.present? ? raw.to_i : 3000
    else
      3000
    end
  end

  def self.admin_email
    return @admin_email if defined?(@admin_email)

    @admin_email = if can_access_database?
      setting = InstanceSetting.find_by(key: "admin_email")
      setting&.value || "admin@localhost"
    else
      "admin@localhost"
    end
  end

  def self.instance_domain
    return @instance_domain if defined?(@instance_domain)

    @instance_domain = if can_access_database?
      setting = InstanceSetting.find_by(key: "instance_domain")
      setting&.value || fallback_instance_domain
    else
      fallback_instance_domain
    end
  end

  def self.rails_log_level
    return @rails_log_level if defined?(@rails_log_level)

    @rails_log_level = if can_access_database?
      setting = InstanceSetting.find_by(key: "rails_log_level")
      setting&.value || "info"
    else
      "info"
    end
  end

  def self.cors_origins
    return @cors_origins if defined?(@cors_origins)

    @cors_origins = if can_access_database?
      setting = InstanceSetting.find_by(key: "cors_origins")
      if setting&.value.present?
        setting.value.split(",").map { _1.strip.downcase }.uniq
      else
        fallback_cors_origins
      end
    else
      fallback_cors_origins
    end
  end

  # Legacy method bridges for backward compatibility
  def self.allowed_hosts
    return @allowed_hosts if defined?(@allowed_hosts)

    @allowed_hosts = if can_access_database?
      setting = InstanceSetting.find_by(key: "allowed_hosts")
      if setting&.value.present?
        setting.value.split(",").map(&:strip)
      else
        [ instance_domain ]
      end
    else
      [ instance_domain ]
    end
  end

  def self.force_ssl?
    return @force_ssl if defined?(@force_ssl)

    @force_ssl = if can_access_database?
      setting = InstanceSetting.find_by(key: "force_ssl")
      ActiveModel::Type::Boolean.new.cast(setting&.value)
    else
      Rails.env.production?
    end
  end

  def self.no_ssl?
    !force_ssl?
  end

  def self.eea_mode_enabled?
    return @eea_mode_enabled if defined?(@eea_mode_enabled)

    @eea_mode_enabled = if can_access_database?
      setting = InstanceSetting.find_by(key: "eea_mode_enabled")
      ActiveModel::Type::Boolean.new.cast(setting&.value)
    else
      false
    end
  end

  def self.grpc_enabled?
    return @grpc_enabled if defined?(@grpc_enabled)

    @grpc_enabled = if can_access_database?
      setting = InstanceSetting.find_by(key: "grpc_enabled")
      ActiveModel::Type::Boolean.new.cast(setting&.value)
    else
      false
    end
  end

  # Email bot configuration methods
  def self.email_bot_enabled?
    return @email_bot_enabled if defined?(@email_bot_enabled)

    @email_bot_enabled = if can_access_database?
      setting = InstanceSetting.find_by(key: "email_bot_enabled")
      ActiveModel::Type::Boolean.new.cast(setting&.value)
    else
      false
    end
  end

  def self.email_bot_address
    return @email_bot_address if defined?(@email_bot_address)

    @email_bot_address = if can_access_database?
      setting = InstanceSetting.find_by(key: "email_bot_address")
      setting&.value || "search@#{instance_domain}"
    else
      "search@#{instance_domain}"
    end
  end

  def self.email_bot_mail_host
    return @email_bot_mail_host if defined?(@email_bot_mail_host)

    @email_bot_mail_host = if can_access_database?
      setting = InstanceSetting.find_by(key: "email_bot_mail_host")
      setting&.value || "mail.#{instance_domain}"
    else
      "mail.#{instance_domain}"
    end
  end

  def self.email_bot_username
    return @email_bot_username if defined?(@email_bot_username)

    @email_bot_username = if can_access_database?
      setting = InstanceSetting.find_by(key: "email_bot_username")
      setting&.value || email_bot_address
    else
      email_bot_address
    end
  end

  def self.email_bot_password
    return @email_bot_password if defined?(@email_bot_password)

    @email_bot_password = if can_access_database?
      setting = InstanceSetting.find_by(key: "email_bot_password")
      setting&.value
    end
  end

  def self.reset_all_cached_config!
    remove_instance_variable(:@port) if defined?(@port)
    remove_instance_variable(:@admin_email) if defined?(@admin_email)
    remove_instance_variable(:@instance_domain) if defined?(@instance_domain)
    remove_instance_variable(:@rails_log_level) if defined?(@rails_log_level)
    remove_instance_variable(:@cors_origins) if defined?(@cors_origins)
    remove_instance_variable(:@allowed_hosts) if defined?(@allowed_hosts)
    remove_instance_variable(:@force_ssl) if defined?(@force_ssl)
    remove_instance_variable(:@eea_mode_enabled) if defined?(@eea_mode_enabled)
    remove_instance_variable(:@grpc_enabled) if defined?(@grpc_enabled)

    # Email bot configuration cache reset
    remove_instance_variable(:@email_bot_enabled) if defined?(@email_bot_enabled)
    remove_instance_variable(:@email_bot_address) if defined?(@email_bot_address)
    remove_instance_variable(:@email_bot_mail_host) if defined?(@email_bot_mail_host)
    remove_instance_variable(:@email_bot_username) if defined?(@email_bot_username)
    remove_instance_variable(:@email_bot_password) if defined?(@email_bot_password)
  end

  class << self
    private

    # Check if we can safely access the database
    def can_access_database?
      defined?(InstanceSetting) &&
        Rails.application.initialized? &&
        ActiveRecord::Base.connection.table_exists?("instance_settings")
    rescue StandardError
      false
    end

    # Auto-detect if we're in a build environment
    def build_environment?
      # Common build environment indicators
      ENV.key?("SECRET_KEY_BASE_DUMMY") ||        # Rails asset precompilation
        ENV.key?("CI") ||                         # Generic CI environment
        ENV.key?("GITHUB_ACTIONS") ||             # GitHub Actions
        ENV.key?("GITLAB_CI") ||                  # GitLab CI
        ENV.key?("JENKINS_URL") ||                # Jenkins
        ENV.key?("BUILD_NUMBER") ||               # Generic build number
        ENV.key?("DOCKER_BUILDKIT") ||            # Docker BuildKit
        ENV["RAILS_ENV"] == "production" && !can_access_database? # Production build without DB
    end

    # Smart domain detection for federation
    def fallback_instance_domain
      # Try environment variable first
      return ENV["INSTANCE_DOMAIN"] if ENV["INSTANCE_DOMAIN"].present?

      # Auto-detect build environments (Docker, CI/CD, etc.)
      return "localhost" if build_environment?

      # Environment-specific defaults with auto-detection
      case Rails.env
      when "development"
        "localhost:3000"
      when "test"
        "localhost"
      when "production"
        detect_production_domain
      else
        "localhost"
      end
    end

    def fallback_cors_origins
      # Allow all origins in development/test, restrict in production
      if Rails.env.development? || Rails.env.test?
        [ "*" ]
      else
        domain = fallback_instance_domain
        [ "https://#{domain}", "http://#{domain}" ]
      end
    end

    def detect_production_domain
      ip = fetch_public_ip
      domain = fetch_reverse_dns(ip)

      raise <<~ERROR unless domain
        ❌ No domain resolves to this server's public IP (#{ip}).
        Please make sure you've configured DNS (A or AAAA records) so that a domain name points to this IP.

        If you're self-hosting, you'll need to set up DNS with your registrar or cloud provider.
      ERROR

Rails.logger.info("[DomainChecker] ✅ Found domain '#{domain}' for IP #{ip}")
        domain
    rescue StandardError => e
      raise "🚨 Domain check failed: #{e.message}"
    end

    def fetch_public_ip
      require "open-uri"

      # Use safer URI parsing and opening with timeout
      uri = URI.parse("https://api.ipify.org")
      raise "Invalid URI scheme" unless uri.scheme == "https"

      uri.open(read_timeout: 10).read.strip
    rescue StandardError => e
      raise "Could not retrieve public IP: #{e.message}"
    end

    def fetch_reverse_dns(ip)
      require "open-uri"
      require "json"

      # Validate IP address format to prevent injection
      raise "Invalid IP address format" unless ip.match?(/\A(?:[0-9]{1,3}\.){3}[0-9]{1,3}\z/) || ip.match?(/\A([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}\z/)

      url = "https://freeapi.robtex.com/ipquery/#{ip}"

      # Use safer URI parsing and opening
      uri = URI.parse(url)
      raise "Invalid URI scheme" unless uri.scheme == "https"

      json = uri.open(read_timeout: 10).read
      data = JSON.parse(json)

      if data["status"] == "ok" && data["pas"].is_a?(Array) && !data["pas"].empty?
        # Return the first PTR record domain
        data["pas"].first["o"]
      end
    rescue StandardError => e
      raise "Failed reverse DNS lookup: #{e.message}"
    end
  end
end
