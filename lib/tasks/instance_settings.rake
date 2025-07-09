# frozen_string_literal: true

namespace :instance_settings do
  desc "Initialize default instance settings"
  task initialize: :environment do
    puts "Initializing instance settings..."

    begin
      InstanceSetting.initialize_defaults!
      puts "✓ Instance settings initialized successfully"

      # Show current configuration
      puts "\nCurrent Configuration:"
      puts "─" * 50

      settings = {
        "Domain" => LibreverseInstance::Application.instance_domain,
        "Admin Email" => LibreverseInstance::Application.admin_email,
        "Rails Log Level" => LibreverseInstance::Application.rails_log_level,
        "Allowed Hosts" => LibreverseInstance::Application.allowed_hosts.join(", "),
        "EEA Mode" => LibreverseInstance::Application.eea_mode_enabled? ? "Enabled" : "Disabled",
        "Force SSL" => LibreverseInstance::Application.force_ssl? ? "Enabled" : "Disabled",
        "No SSL" => LibreverseInstance::Application.no_ssl? ? "Enabled" : "Disabled",
        "gRPC Server" => LibreverseInstance::Application.grpc_enabled? ? "Enabled" : "Disabled",
        "CORS Origins" => LibreverseInstance::Application.cors_origins.join(", "),
        "Port" => LibreverseInstance::Application.port
      }

      settings.each do |key, value|
        puts "  #{key.ljust(20)}: #{value}"
      end
    rescue StandardError => e
      puts "✗ Failed to initialize instance settings: #{e.message}"
      exit 1
    end
  end

  desc "Reset all cached configuration values"
  task reset_cache: :environment do
    puts "Resetting cached configuration values..."
    LibreverseInstance.reset_all_cached_config!
    puts "✓ Cache reset successfully"
  end

  desc "Show current instance configuration"
  task show: :environment do
    puts "Current Instance Configuration:"
    puts "=" * 50

    settings = {
      "Instance Domain" => LibreverseInstance::Application.instance_domain,
      "Admin Email" => LibreverseInstance::Application.admin_email,
      "Rails Log Level" => LibreverseInstance::Application.rails_log_level,
      "Allowed Hosts" => LibreverseInstance::Application.allowed_hosts.join(", "),
      "EEA Mode Enabled" => LibreverseInstance::Application.eea_mode_enabled? ? "Yes" : "No",
      "Force SSL" => LibreverseInstance::Application.force_ssl? ? "Yes" : "No",
      "No SSL" => LibreverseInstance::Application.no_ssl? ? "Yes" : "No",
      "gRPC Server Enabled" => LibreverseInstance::Application.grpc_enabled? ? "Yes" : "No",
      "CORS Origins" => LibreverseInstance::Application.cors_origins.join(", "),
      "Application Port" => LibreverseInstance::Application.port
    }

    settings.each do |key, value|
      puts "  #{key.ljust(25)}: #{value}"
    end

    puts "\nDatabase Settings Count: #{InstanceSetting.count}"
    puts "\nTo modify these settings, visit the admin panel at /admin/instance_settings"
  end

  desc "Validate configuration consistency"
  task validate: :environment do
    puts "Validating instance configuration..."
    errors = []
    warnings = []

    # Check for conflicting SSL settings
    errors << "Conflicting SSL settings: Both force_ssl and no_ssl are enabled" if LibreverseInstance::Application.force_ssl? && LibreverseInstance::Application.no_ssl?

    # Validate log level
    valid_levels = %w[debug info warn error fatal unknown]
    errors << "Invalid log level: #{LibreverseInstance::Application.rails_log_level}" unless valid_levels.include?(LibreverseInstance::Application.rails_log_level.downcase)

    # Validate port range
    port = LibreverseInstance::Application.port
    errors << "Invalid port number: #{port} (must be between 1 and 65535)" unless port.between?(1, 65_535)

    # Check if allowed hosts is not empty
    errors << "No allowed hosts configured" if LibreverseInstance::Application.allowed_hosts.empty?

    # Validate admin email format
    admin_email = LibreverseInstance::Application.admin_email
    errors << "Invalid admin email format: #{admin_email}" unless admin_email.match?(/\A[^@\s]+@[^@\s]+\z/)

    # Environment-specific validation warnings
    if Rails.env.production?
      warnings << "SSL is not forced in production environment" unless LibreverseInstance::Application.force_ssl?

      warnings << "CORS is set to allow all origins (*) in production" if LibreverseInstance::Application.cors_origins.include?("*")
    end

    warnings << "SSL is forced in development environment (may cause issues with localhost)" if Rails.env.development? && LibreverseInstance::Application.force_ssl?

    # Advanced settings validation (less critical)
    port = LibreverseInstance::Application.port
    warnings << "Application port is not using the standard 3000 (currently: #{port})" if port != 3000

    # gRPC-specific validation
    if LibreverseInstance::Application.grpc_enabled?
      warnings << "gRPC is enabled in production but may fail without proper SSL certificates" if Rails.env.production? && !(ENV["GRPC_SSL_CERT_PATH"] && ENV["GRPC_SSL_KEY_PATH"])
      warnings << "gRPC server is enabled but may conflict with other services on port 50051"
    end

    # Output results
    if errors.empty? && warnings.empty?
      puts "✓ Configuration validation passed"
    else
      if errors.any?
        puts "✗ Configuration validation failed:"
        errors.each { |error| puts "  ERROR: #{error}" }
      end

      if warnings.any?
        puts "⚠ Configuration warnings:"
        warnings.each { |warning| puts "  WARNING: #{warning}" }
      end

      exit 1 if errors.any?
    end
  end
end
