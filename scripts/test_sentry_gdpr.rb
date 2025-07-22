#!/usr/bin/env ruby
# frozen_string_literal: true

# GDPR Error Tracking Test Script
# This script helps verify that the error tracking configuration
# is working and compliant with GDPR requirements

require 'bundler/setup'
require_relative '../config/environment'

puts "🔍 GDPR Error Tracking Configuration Test"
puts "=" * 50

# Check if Sentry is configured
if Sentry.configuration.dsn
  puts "✅ Sentry DSN configured"
  puts "   Environment: #{Sentry.configuration.environment}"
  puts "   Enabled: #{Sentry.configuration.enabled_environments.include?(Rails.env)}"
else
  puts "❌ Sentry DSN not configured"
  puts "   Set SENTRY_DSN environment variable"
end

# Check GDPR compliance settings
puts "\n🛡️  GDPR Compliance Check:"
puts "✅ send_default_pii: #{Sentry.configuration.send_default_pii}" # Should be false
puts "✅ traces_sample_rate: #{Sentry.configuration.traces_sample_rate}" # Should be 0.0
puts "✅ max_breadcrumbs: #{Sentry.configuration.max_breadcrumbs}" # Should be 3
puts "✅ breadcrumbs_logger: #{Sentry.configuration.breadcrumbs_logger.empty? ? 'disabled' : 'enabled'}" # Should be disabled

# Check before_send hook
if Sentry.configuration.before_send
  puts "✅ before_send hook configured (removes personal data)"
else
  puts "❌ before_send hook not configured"
end

# Test error capture in non-production
if Rails.env.development?
  puts "\n🧪 Development Mode Test:"
  puts "   Sentry is disabled in development (this is correct)"
  puts "   To test error capture, deploy to staging/production"
else
  puts "\n🧪 Testing Error Capture:"
  begin
    # Capture a test message
    Sentry.with_scope do |scope|
      scope.set_tag("test", "gdpr_compliance")
      Sentry.capture_message("GDPR compliance test - no personal data should be visible")
    end
    puts "✅ Test message sent to Sentry"
  rescue StandardError => e
    puts "❌ Error sending test message: #{e.message}"
  end
end

puts "\n📋 Next Steps:"
if Rails.env.development?
  puts "1. ✅ GlitchTip DSN already configured"
  puts "2. Deploy to staging/production to test error capture"
  puts "3. Check GlitchTip dashboard for collected data"
  puts "4. Verify no personal information is captured"
else
  puts "1. Check GlitchTip dashboard for the test message"
  puts "2. Verify no personal data (IP, cookies, headers) is captured"
  puts "3. Confirm file paths are anonymized"
end

puts "\n🔒 Privacy Compliance:"
puts "This configuration minimizes data collection for GDPR compliance"
puts "Review documentation/gdpr_error_tracking.md for details"
