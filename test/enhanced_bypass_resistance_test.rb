# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

require "test_helper"
require "base64"

class EnhancedBypassResistanceTest < ActiveSupport::TestCase
  def setup
    # Clear cache to ensure fresh word lists
    Rails.cache.clear
  end

  test "detects basic creative letter substitutions" do
    creative_variations = [
      Base64.decode64("c2gxdA=="),      # sh1t
      Base64.decode64("Zipjaw=="),      # f*ck - restored
      Base64.decode64("YiF0Y2g="), # b!tch
      Base64.decode64("NHNz"), # 4ss
      Base64.decode64("JGhpdA=="),      # $hit
      Base64.decode64("Zitjaw=="),      # f#ck (f샵ck)
      Base64.decode64("YypudA=="),      # c*nt
      Base64.decode64("dHdAdA=="),      # tw@t
      Base64.decode64("YzBjaw=="),      # c0ck
      Base64.decode64("ZDFjaw==")       # d1ck
    ]

    creative_variations.each do |variation|
      assert ModerationService.contains_profanity?(variation),
             "Should detect creative variation: #{variation}"
    end
  end

  test "detects Unicode characters that bypass ASCII filters" do
    unicode_variations = [
      "#{Base64.decode64('ZnVjaw==')} café",           # Unicode + profanity
      "#{Base64.decode64('c2hpdA==')} résumé",         # Unicode + profanity
      "#{Base64.decode64('Yml0Y2g=')} über all", # Unicode + profanity
      "#{Base64.decode64('Y3VudA==')} naïve",          # Unicode + profanity
      "#{Base64.decode64('dHdhdA==')} piñata"          # Unicode + profanity
    ]

    # Test that Unicode with profanity is properly detected
    unicode_variations.each do |text|
      assert ModerationService.contains_inappropriate_content?(text),
             "Unicode text with profanity '#{text}' should be detected"
    end
  end

  test "detects complex creative obfuscation patterns" do
    complex_patterns = [
      Base64.decode64("Zl91X2Nfaw=="),
      Base64.decode64("Zi11LWMtaw=="),
      Base64.decode64("Zi51LmMuaw=="),
      Base64.decode64("ZiB1IGMgaw=="),
      Base64.decode64("RnVDaw=="),
      Base64.decode64("RlVDSw=="),
      Base64.decode64("Zipjaw=="),
      Base64.decode64("Zitjaw=="),
      Base64.decode64("cGh1Y2s=")
    ]

    complex_patterns.each do |pattern|
      assert ModerationService.contains_inappropriate_content?(pattern),
             "Should detect creative pattern: '#{pattern}'"
    end
  end

  test "creative regex patterns work with RE2" do
    # Test that our creative regex patterns compile successfully
    test_words = [
      Base64.decode64("ZnVjaw=="), Base64.decode64("c2hpdA=="), Base64.decode64("Yml0Y2g="),
      Base64.decode64("Y3VudA=="), Base64.decode64("dHdhdA==")
    ]

    test_words.each do |word|
      pattern = ModerationService.send(:creative_regex, word)
      assert_not_nil pattern, "Should generate pattern for '#{word}'"

      # Test that pattern compiles with RE2
      assert_nothing_raised do
        regex = RE2::Regexp.new(pattern, case_insensitive: true)
        assert regex.is_a?(RE2::Regexp), "Pattern should compile to RE2::Regexp"
      end
    end
  end

  test "detects creative substitutions in real-world examples" do
    real_world_examples = [
      "That's bull#{Base64.decode64('JGhpdA==')}", # $hit
      "Don't be such a #{Base64.decode64('YiF0Y2g=')}", # b!tch
      "#{Base64.decode64('Zipjaw==')} this noise", # F*ck - restored
      "You're being an #{Base64.decode64('NHNz')}", # @ss (using 4ss for consistency)
      "Stop being a #{Base64.decode64('YypudA==')}", # c*nt
      "That #{Base64.decode64('dHdAdA==')} is annoying", # tw@t
      "What a #{Base64.decode64('ZDFjaw==')} move", # d1ck
      "Such a #{Base64.decode64('NWwqdCE=')} behavior" # sl*t (encoded NWwqdCE= -> 5l*t!)
    ]

    real_world_examples.each do |text|
      assert ModerationService.contains_inappropriate_content?(text),
             "Should detect inappropriate content in: '#{text}'"

      violations = ModerationService.get_violation_details(text)
      assert violations.any? { |v| v[:type] == "profanity" },
             "Should report profanity violation for: '#{text}'"
    end
  end

  test "handles mixed Unicode and creative patterns" do
    mixed_examples = [
      "This is bull#{Base64.decode64('c2gxdA==')} résumé",  # sh!t + Unicode (used sh1t for consistency)
      "#{Base64.decode64('Zipjaw==')} this naïve approach", # F*ck + Unicode - restored
      "That #{Base64.decode64('YypudA==')} café owner",     # c*nt + Unicode
      "What a #{Base64.decode64('dHdAdA==')} señor" # tw@t + Unicode
    ]

    mixed_examples.each do |text|
      assert ModerationService.contains_inappropriate_content?(text),
             "Should detect mixed pattern: '#{text}'"
    end
  end

  test "avoids false positives with enhanced detection" do
    safe_texts = [
      "Safe Experience Title",
      "A nice description",
      "The quick brown fox",
      "Testing application",
      "System configuration",
      "Database migration",
      "Application controller",
      "Project management"
    ]

    safe_texts.each do |text|
      assert_not ModerationService.contains_inappropriate_content?(text),
                 "Should not flag safe text: '#{text}'"
    end
  end

  test "creative regex detection works correctly" do
    text = "This #{Base64.decode64('JGhpdA==')} test should work properly" # $hit

    # Should detect the creative substitution
    assert ModerationService.contains_inappropriate_content?(text),
           "Should detect #{Base64.decode64('JGhpdA==')} as creative substitution for ****"

    violations = ModerationService.get_violation_details(text)
    assert violations.any? { |v| v[:type] == "profanity" },
           "Should report profanity violation for #{Base64.decode64('JGhpdA==')}"
  end

  test "performance with creative patterns is acceptable" do
    long_text = "This is a long text with some creative patterns like #{Base64.decode64('c2gxdA==')} and #{Base64.decode64('Zipjaw==')} repeated many times. " * 100 # sh!t and f*ck - restored

    # Test that detection completes in reasonable time
    start_time = Time.current
    result = ModerationService.contains_inappropriate_content?(long_text)
    end_time = Time.current

    assert result, "Should detect inappropriate content in long text"
    assert (end_time - start_time) < 5.seconds, "Detection should complete within 5 seconds"
  end

  test "creative regex generation handles edge cases" do
    edge_cases = [
      { word: "", should_be_nil: true },
      { word: nil, should_be_nil: true },
      { word: "a", should_be_nil: true },      # Too short
      { word: "ab", should_be_nil: true },     # Too short
      { word: "abc", should_be_nil: false },   # Minimum length
      { word: Base64.decode64("ZnVjaw=="), should_be_nil: false } # Valid word
    ]

    edge_cases.each do |test_case|
      pattern = ModerationService.send(:creative_regex, test_case[:word])

      if test_case[:should_be_nil]
        assert_nil pattern, "Should return nil for word: #{test_case[:word].inspect}"
      else
        assert_not_nil pattern, "Should generate pattern for word: #{test_case[:word].inspect}"
      end
    end
  end

  test "detects leetspeak variations comprehensively" do
    leetspeak_examples = [
      Base64.decode64("NWgxdDc="),
      Base64.decode64("OGIhdGNICAg="),
      Base64.decode64("NHNz"),
      Base64.decode64("YzBjaw=="),
      Base64.decode64("NWwqdA==")
    ]

    leetspeak_examples.each do |text|
      assert ModerationService.contains_inappropriate_content?(text),
             "Should detect leetspeak: '#{text}'"
    end
  end
end
