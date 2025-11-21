# frozen_string_literal: true
# shareable_constant_value: literal

namespace :compliance do
  desc "Verify EEA compliance settings"
  task verify: :environment do
    puts "\n=== Running EEA Compliance Verification ==="

    begin
      EEAMode.verify_compliance
      puts "✓ All required compliance settings are properly configured"

      if EEAMode.enabled?
        puts "✓ EEA Mode is enabled"
        puts "✓ Cookie settings:"
        EEAMode::COMPLIANCE[:cookie_settings].each do |k, v|
          value = v.is_a?(Proc) ? v.call : v
          puts "  - #{k}: #{value}"
        end

        puts "\n✓ Policy exemptions:"
        EEAMode::COMPLIANCE[:required][:policy_exemptions].each do |path|
          puts "  - /#{path}"
        end
      else
        puts "ℹ EEA Mode is currently disabled"
      end

      puts "\nVerification completed successfully\n"
    rescue StandardError => e
      puts "\n‼ Compliance verification failed: #{e.message}"
      puts "Please review config/initializers/eea_mode.rb\n"
      raise
    end
  end

  desc "Audit consent logs for the past week"
  task audit_logs: :environment do
    require "time"

    puts "\n=== EEA Compliance Log Audit ==="

    # This would normally query your log aggregation system
    # For demonstration, we'll just print instructions
    puts "To audit consent logs, search your application logs for:"
    puts "  - [EEA Compliance] Consent required for:"
    puts "  - [EEA Compliance] Consent accepted for user"
    puts "  - [EEA Compliance] Consent declined for user"

    puts "\nRecommended audit queries:"
    puts "  grep -r \"\\[EEA Compliance\\]\" log/production.log | wc -l"
    puts "  grep -r \"\\[EEA Compliance\\] Consent declined\" log/production.log | wc -l"

    puts "\nAudit completed\n"
  end
end
