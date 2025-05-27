# frozen_string_literal: true

require "base64"

# Safe Base64 decoding method that handles invalid UTF-8 gracefully
def safe_decode64(encoded_string, fallback: nil)
  decoded = Base64.decode64(encoded_string)
  # Validate UTF-8 encoding
  decoded.force_encoding("UTF-8")
  return fallback || encoded_string unless decoded.valid_encoding?

  decoded
rescue StandardError => e
  Rails.logger.warn("Base64 decoding error for '#{encoded_string}': #{e.message}") if defined?(Rails)
  fallback || encoded_string
end

namespace :moderation do
  desc "Show statistics about current moderation word lists"
  task stats: :environment do
    puts "Moderation Word List Statistics"
    puts "=" * 40

    begin
      profanity_words = ModerationService::CURATED_PROFANITY_WORDS
      spam_words = ModerationService::CURATED_SPAM_WORDS

      puts "Profanity words: #{profanity_words.size}"
      puts "Spam words: #{spam_words.size}"
      puts "Total words: #{profanity_words.size + spam_words.size}"
      puts "Source: Base64 encoded YAML files (config/bannedwords.yml and config/spamwords.yml)"
      puts "Creative patterns: Enabled for bypass resistance"
    rescue StandardError => e
      puts "❌ Error getting statistics: #{e.message}"
      exit 1
    end
  end

  desc "Test moderation service with sample text"
  task :test, [ :text ] => :environment do |_t, args|
    text = args[:text] || "This is a test message"

    puts "Testing moderation service with text: '#{text}'"
    puts "=" * 50

    begin
      inappropriate = ModerationService.contains_inappropriate_content?(text)
      puts "Contains inappropriate content: #{inappropriate ? '❌ YES' : '✅ NO'}"

      if inappropriate
        violations = ModerationService.get_violation_details(text)
        puts "\nViolation details:"
        violations.each_with_index do |violation, index|
          puts "  #{index + 1}. Type: #{violation[:type]}"
          if violation[:details]
            puts "     Details: #{violation[:details].join(', ')}"
          elsif violation[:pattern_type]
            puts "     Pattern: #{violation[:pattern_type]}"
          end
        end
      end

      # Individual checks
      puts "\nDetailed checks:"
      puts "  Profanity: #{ModerationService.contains_profanity?(text) ? '❌' : '✅'}"
      puts "  PII: #{ModerationService.contains_pii?(text) ? '❌' : '✅'}"
      puts "  Spam: #{ModerationService.contains_spam?(text) ? '❌' : '✅'}"
      puts "  Suspicious: #{ModerationService.contains_suspicious_content?(text) ? '❌' : '✅'}"
    rescue StandardError => e
      puts "❌ Error testing moderation: #{e.message}"
      exit 1
    end
  end

  desc "Show sample words from each category (first 10)"
  task sample_words: :environment do
    puts "Sample Moderation Words"
    puts "=" * 30

    begin
      profanity_words = ModerationService::CURATED_PROFANITY_WORDS.to_a.first(10)
      spam_words = ModerationService::CURATED_SPAM_WORDS.to_a.first(10)

      puts "Sample profanity words (#{profanity_words.size} shown):"
      profanity_words.each { |word| puts "  - #{word}" }

      puts "\nSample spam words (#{spam_words.size} shown):"
      spam_words.each { |word| puts "  - #{word}" }

      puts "\nNote: These are loaded from base64 encoded YAML files."
    rescue StandardError => e
      puts "❌ Error showing sample words: #{e.message}"
      exit 1
    end
  end

  desc "Test creative letter patterns"
  task test_patterns: :environment do
    puts "Testing Creative Letter Patterns"
    puts "=" * 35

    # Test cases should use words present in bannedwords.yml for 'original'
    # to ensure the 'original_detected' part of the output is meaningful.
    test_cases = [
      { original: safe_decode64("c2hpdA=="), creative: safe_decode64("c2gxdA==") }, # shit -> sh1t
      { original: safe_decode64("ZnVjaw=="), creative: safe_decode64("Zipjaw==") }, # fuck -> f*ck
      { original: safe_decode64("Yml0Y2g="), creative: safe_decode64("YjF0Y2g=") }, # bitch -> b1tch
      { original: safe_decode64("YXNz"), creative: safe_decode64("NHNz") }, # ass -> 4ss
      { original: safe_decode64("c2hpdA=="), creative: safe_decode64("JGhpdA==") } # shit -> $hit
    ]

    test_cases.each do |test_case|
      original_word = test_case[:original]
      creative_word = test_case[:creative]

      original_detected = ModerationService.contains_profanity?(original_word)
      creative_detected = ModerationService.contains_profanity?(creative_word)

      # Display the decoded original word for readability in the output
      puts "#{original_word} → #{creative_word}: " \
           "#{original_detected ? '✅' : '❌'} → #{creative_detected ? '✅' : '❌'}"
    end

    puts "\nNote: Both original (if in list) and creative versions should ideally be detected (✅)"
    puts "If original shows ❌, it means the base word itself isn't in bannedwords.yml or isn't being matched as expected."
  end
end
