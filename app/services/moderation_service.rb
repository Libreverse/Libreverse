# frozen_string_literal: true

require "re2"
require "unidecoder"
require "yaml"
require "base64"

class ModerationService
  # Configuration for debug logging
  def self.debug_logging_enabled?
    Rails.env.development? || Rails.env.test?
  end

  # Load banned words from base64 encoded YAML file
  def self.load_banned_words
    yaml_file = Rails.root.join("config/bannedwords.yml")
    return Set.new unless File.exist?(yaml_file)

    banned_words_data = YAML.safe_load(
      File.read(yaml_file),
      permitted_classes: [ String, Array, Hash ],
      aliases: false
    )
    return Set.new unless banned_words_data.is_a?(Hash)

    # Decode all base64 encoded words
    encoded_values = banned_words_data.values
    # Fallback to keys if YAML was formatted with encoded words as keys
    encoded_values = banned_words_data.keys if encoded_values.all?(&:blank?)
    decoded_words = encoded_values.map do |base64_word|
      decoded = Base64.decode64(base64_word)
      # Ensure UTF-8 encoding
      decoded.force_encoding(Encoding::UTF_8)
      decoded = decoded.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: "?") unless decoded.valid_encoding?
      decoded.downcase.strip
    rescue StandardError => e
      Rails.logger.warn("Failed to decode banned word: #{e.message}")
      nil
    end.compact

    Set.new(decoded_words)
  end

  # Load words once at class load time
  ALL_BANNED_WORDS = load_banned_words.freeze

  # Use all banned words from YAML as profanity words (the YAML contains offensive content)
  CURATED_PROFANITY_WORDS = ALL_BANNED_WORDS.freeze

  # Load spam words from base64 encoded YAML file
  def self.load_spam_words
    yaml_file = Rails.root.join("config/spamwords.yml")
    return Set.new unless File.exist?(yaml_file)

    spam_words_data = YAML.safe_load(
      File.read(yaml_file),
      permitted_classes: [ String, Array, Hash ],
      aliases: false
    )
    return Set.new unless spam_words_data.is_a?(Hash)

    # Decode all base64 encoded words
    decoded_words = spam_words_data.values.map do |base64_word|
      decoded = Base64.decode64(base64_word)
      # Ensure UTF-8 encoding
      decoded.force_encoding(Encoding::UTF_8)
      decoded = decoded.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: "?") unless decoded.valid_encoding?
      decoded.downcase.strip
    rescue StandardError => e
      Rails.logger.warn("Failed to decode spam word: #{e.message}")
      nil
    end.compact

    Set.new(decoded_words)
  end

  # Load spam words from YAML
  CURATED_SPAM_WORDS = load_spam_words.freeze

  # New comprehensive LETTER_PATTERNS for Ruby's Regexp
  USER_LETTER_PATTERNS = {
    "a" => '(?:a|@|4|\\^|\\/\\\\|-\\|aye?)',
    "b" => '(?:b|i3|l3|13|\\|3|/3|\\\\3|3|8|6|p\\>|\\\\|\\:|[^a-z]bee+[^a-z])',
    "c" => '(?:c|\\(|\\[|[^a-z]cee+[^a-z]|[^a-z]see+[^a-z]|k|x|[\\|\\[\\]\\)\\(li1\\!][\\<\\{\\(]|[^a-z][ck]ay+[^a-z])',
    "d" => '(?:d|\\)|\\|\\)|\\[\\)|\\?|\\|>|\\|o|[^a-z]dee+[^a-z])',
    "e" => '(?:e|3|\\&|\\[\\-)',
    "f" => '(?:f|ph|[\\|\\}\\{\\/\\(\\)\\[\\]1il\\!][\\=\\#]|[^a-z]ef+[^a-z])',
    "g" => '(?:g|6|9|\\&|c\\-|\\(\\_\\+|[^a-z]gee+[^a-z])',
    "h" => '(?:h|\#|[\|\}\{\/\(\)\[\]]\\-[?][\|\}\{\/\(\)\[\]])',
    "i" => '(?:i|l|1|\!|\||\]|\\[|\\|/|[^a-z]eye[^a-z]|[\|li1\!\[\]\(\)\{\}]_|[^a-z]el+[^a-z])',
    "j" => '(?:j|\\]|_\\||_/|\\</|\\(/|[^a-z]jay+[^a-z])',
    "k" => '(?:k|x|[\\|\\[\\]\\)\\(li1\\!][\\<\\{\\(]|[^a-z][ck]ay+[^a-z])',
    "l" => '(?:l|1|\\!|\\||\\]|\\[|\\\\|/|[^a-z]el+[^a-z])',
    "m" => '(?:m|[\\|\\(\\)\\\\](?:\\\\/|v|\\|)[\\|\\(\\)\\\\]|\\^\\^|[^a-z]em+[^a-z])',
    "n" => '(?:n|[\\|/\\[\\]<>\\\\][\\|/\\[\\]<>]|/v|\\^/|[^a-z]en+[^a-z])',
    "o" => '(?:o|0|\\(\\)|\\[\\]|[^a-z]oh+[^a-z])',
    "p" => '(?:p|[\\|li1\\[\\]\\!/\\\\][*o"\\>7^]|[^a-z]pee+[^a-z])',
    "q" => '(?:q|9|(?:0|\\(\\)|\\[\\])_|[\\(_,\\)<\\|]|[^a-z][ck]ue*|qu?eue*[^a-z])',
    "r" => '(?:r|[/1\|li]?[2\^\?z]|[^a-z]ar+[^a-z])',
    "s" => '(?:s|\\$|5|[^a-z]es+[^a-z]|z|2|7_|\~/_|\>_|%|[^a-z]zee+[^a-z])',
    "t" => '(?:t|7|\\+|\\-\\|\\-|\\\\)',
    "u" => '(?:u|v|\\*|\\+|[\\|\\(\\)\\[\\]\\{\\}]_[\\|\\(\\)\\[\\]\\{\\}]|[^a-z]you[^a-z]|[^a-z]yoo+[^a-z]|[^a-z]vee+[^a-z])',
    "v" => '(?:v|[\\|\\(\\)\\[\\]\\{\\}]_[\\|\\(\\)\\[\\]\\{\\}]|[^a-z]vee+[^a-z])',
    "w" => '(?:w|vv|\/\/|\\\|\\\'|\'//|\\\^/|\(n\)|[^a-z]do?u+b+l+e*[^a-z]?(?:u+|you|yoo+)[^a-z])',
    "x" => '(?:x|\\>\\<\\|\\*|[\\%\\}\\{\\}][\\)\\(]|[^a-z]e[ck]+s+[^a-z]|[^a-z]ex+[^a-z])',
    "y" => "(?:y|j|\\'/|[^a-z]wh?(?:y+|ie+)[^a-z])",
    "z" => '(?:z|2|7_|\\~/_|\\>_|%|[^a-z]zee+[^a-z])'
  }.freeze

  # New creative_regex method using Ruby's Regexp and user's patterns/logic
  def self.creative_regex(word)
    return nil if word.blank? || word.length < 3 # Changed from 2 to 3

    # Normalize smart quotes and other special characters
    normalized_word = word.downcase
                          .gsub(/['']/, "'")  # Replace curly apostrophes with straight ones
                          .gsub(/[""]/, '"')  # Replace curly quotes with straight ones
                          .gsub(/[–—]/, "-")  # Replace en/em dashes with hyphens

    pattern = +""
    normalized_word.each_char do |char|
      pattern << if USER_LETTER_PATTERNS.key?(char)
        USER_LETTER_PATTERNS[char]
      else
        Regexp.escape(char)
      end
    end

    # Use word start boundary but allow word to continue (for suffixes like -ing, -ed, etc.)
    # Simplified approach without lookaheads for RE2 compatibility
    "\\b#{pattern}"
  end

  # Cache compiled regex patterns for profanity words
  def self.compile_profanity_regexes
    regexes = {}
    ALL_BANNED_WORDS.each do |bad_word|
      bad_word_str = bad_word.to_s
      next if bad_word_str.blank? || bad_word_str.length < 3

      pattern_str = creative_regex(bad_word_str)
      next if pattern_str.nil?

      begin
        regexes[bad_word_str] = Regexp.new(pattern_str, Regexp::IGNORECASE)
      rescue StandardError => e
        Rails.logger.warn "ModerationService: Failed to compile regex for profanity '#{bad_word_str}' during initialization: #{e.message}"
      end
    end
    regexes.freeze
  end

  # Cache compiled regex patterns for spam words
  def self.compile_spam_regexes
    regexes = {}
    CURATED_SPAM_WORDS.each do |spam_word|
      spam_word_str = spam_word.to_s
      next if spam_word_str.blank? || spam_word_str.length < 3

      pattern_str = creative_regex(spam_word_str)
      next if pattern_str.nil?

      begin
        regexes[spam_word_str] = Regexp.new(pattern_str, Regexp::IGNORECASE)
      rescue StandardError => e
        Rails.logger.warn "ModerationService: Failed to compile regex for spam '#{spam_word_str}' during initialization: #{e.message}"
      end
    end
    regexes.freeze
  end

  # Precompiled regex patterns
  CACHED_PROFANITY_REGEXES = compile_profanity_regexes
  CACHED_SPAM_REGEXES = compile_spam_regexes

  # RE2 regex patterns for PII detection
  PII_PATTERNS = [
    # Email addresses
    RE2::Regexp.new('(?i)\\b[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,}\\b'),

    # Phone numbers (various formats)
    RE2::Regexp.new('\\b(?:\\+?1[-\\.\\s]?)?\\(?[0-9]{3}\\)?[-\\.\\s]?[0-9]{3}[-\\.\\s]?[0-9]{4}\\b'),

    # Credit card numbers (basic pattern)
    RE2::Regexp.new('\\b(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|3[47][0-9]{13}|3[0-9]{13}|6(?:011|5[0-9]{2})[0-9]{12})\\b'),

    # Social Security Numbers (US format)
    RE2::Regexp.new('\\b[0-9]{3}-?[0-9]{2}-?[0-9]{4}\\b'),

    # IP addresses
    RE2::Regexp.new('\\b(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\b'),

    # Postal codes (US and international)
    RE2::Regexp.new('(?i)\\b[0-9]{5}(?:-[0-9]{4})?\\b|\\b[A-Z][0-9][A-Z]\\s?[0-9][A-Z][0-9]\\b')
  ].freeze

  # RE2 regex patterns for spam detection
  SPAM_PATTERNS = [
    # Multiple URLs (simplified)
    RE2::Regexp.new('https?://\\S+.*https?://\\S+'),

    # Excessive capitalization
    RE2::Regexp.new("[A-Z]{10,}"),

    # Excessive exclamation marks
    RE2::Regexp.new("!{5,}"),

    # Excessive repetition of characters (simplified patterns)
    RE2::Regexp.new("(a{5,}|b{5,}|c{5,}|d{5,}|e{5,}|f{5,}|g{5,}|h{5,}|i{5,}|j{5,}|k{5,}|l{5,}|m{5,}|n{5,}|o{5,}|p{5,}|q{5,}|r{5,}|s{5,}|t{5,}|u{5,}|v{5,}|w{5,}|x{5,}|y{5,}|z{5,})"),

    # Common spam phrases
    RE2::Regexp.new('(?i)\\b(?:click here|buy now|limited time|act now|free money|no cost|risk free)\\b'),

    # Suspicious patterns
    RE2::Regexp.new('(?i)\\b(?:call now|order today|don\'t delay|hurry|urgent|immediate)\\b')
  ].freeze

  # Additional suspicious patterns
  SUSPICIOUS_PATTERNS = [
    # Excessive use of symbols
    RE2::Regexp.new('[!@#$%^&*()_+={}\\[\\]:";\'<>?,./]{10,}'),

    # Base64-like patterns (potential encoded content)
    RE2::Regexp.new('\\b[A-Za-z0-9+/]{20,}={0,2}\\b')
  ].freeze

  class << self
    # Main method to check content across all categories
    def contains_inappropriate_content?(text)
      return false if text.blank?

      # Ensure UTF-8 encoding
      text = ensure_utf8_encoding(text)

      contains_profanity?(text) ||
        contains_pii?(text) ||
        contains_spam?(text) ||
        contains_suspicious_content?(text)
    end

    # Pure profanity detection with creative letter patterns (using Ruby Regexp)
    def contains_profanity?(text)
      return false if text.blank?

      # Ensure UTF-8 encoding
      text = ensure_utf8_encoding(text)

      normalized_text = text.to_ascii.downcase
                            .gsub(/[‘’‛‹›`´]/, "'") # Replace curly apostrophes & graves with straight ones
                            .gsub(/[“”„«»]/, '"') # Replace curly double-quotes with straight ones
                            .gsub(/[–—]/, "-") # Replace en/em dashes with hyphens
      # rails.logger.debug "DEBUG [contains_profanity? for text: '#{normalized_text}']" if debug_logging_enabled?

      spaced_text = normalized_text.gsub(/[_\-.\s]/, "")
      collapsed_text = normalized_text.gsub(/(.)\1+/, '\1')

      # Also check if the input text itself matches any bad words with substitutions
      # by normalizing common substitutions back to letters
      reverse_normalized = normalized_text.tr("@", "a")
                                          .tr("4", "a")
                                          .tr("3", "e")
                                          .tr("!", "i")
                                          .tr("1", "i")
                                          .tr("0", "o")
                                          .tr("$", "s")
                                          .tr("5", "s")
                                          .tr("*", "u")
                                          .tr("+", "u")
                                          .tr("#", "u")
                                          .tr("7", "t")

      # Check reverse normalized text against plain bad words
      CURATED_PROFANITY_WORDS.each do |bad_word|
        bad_word_str = bad_word.to_s
        # Use word boundary regex for normal text, but simple contains for spaced text
        word_regex = Regexp.new("\\b#{Regexp.escape(bad_word_str)}\\b", Regexp::IGNORECASE)
        if word_regex.match?(reverse_normalized) ||
           word_regex.match?(collapsed_text) ||
           (bad_word_str.length >= 4 && spaced_text.include?(bad_word_str)) # Minimum 4 chars for spaced text
          return true
        end
      end

      # Check using cached creative pattern regexes
      CACHED_PROFANITY_REGEXES.each_value do |regex|
        if debug_logging_enabled?
          # rails.logger.debug "  DEBUG: checking bad_word = '#{bad_word_str}'"
          match_result_norm = regex.match?(normalized_text)
          # rails.logger.debug "    DEBUG: normalized_text ('#{normalized_text}') match? #{match_result_norm}"
          if match_result_norm
            # rails.logger.debug "      MATCHED! Returning true."
            return true
          end
        end

        return true if regex.match?(normalized_text) || regex.match?(spaced_text) || regex.match?(collapsed_text)
      end
      false
    end

    # Check for personally identifiable information
    def contains_pii?(text)
      return false if text.blank?

      # Ensure UTF-8 encoding
      text = ensure_utf8_encoding(text)

      PII_PATTERNS.any? { |pattern| pattern.match?(text) }
    end

    # Pure spam detection with patterns and creative matching
    def contains_spam?(text)
      return false if text.blank?

      # Ensure UTF-8 encoding
      text = ensure_utf8_encoding(text)

      return true if SPAM_PATTERNS.any? { |pattern| pattern.match?(text) } # RE2 part

      # Ruby Regexp part for curated spam words with creative patterns
      normalized_text = text.to_ascii.downcase
                            .gsub(/[‘’‛‹›`´]/, "'") # Replace curly apostrophes & graves with straight ones
                            .gsub(/[“”„«»]/, '"') # Replace curly double-quotes with straight ones
                            .gsub(/[–—]/, "-") # Replace en/em dashes with hyphens

      # rails.logger.debug "DEBUG [contains_spam? for text: '#{normalized_text}']" if debug_logging_enabled?

      spaced_text = normalized_text.gsub(/[_\-.\s]/, "")
      collapsed_text = normalized_text.gsub(/(.)\1+/, '\1')

      # Also check if the input text itself matches any spam words with substitutions
      reverse_normalized = normalized_text.tr("@", "a")
                                          .tr("4", "a")
                                          .tr("3", "e")
                                          .tr("!", "i")
                                          .tr("1", "i")
                                          .tr("0", "o")
                                          .tr("$", "s")
                                          .tr("5", "s")
                                          .tr("*", "u")
                                          .tr("+", "u")
                                          .tr("#", "u")
                                          .tr("7", "t")

      # Check reverse normalized text against plain spam words
      CURATED_SPAM_WORDS.each do |spam_word|
        spam_word_str = spam_word.to_s
        # Use word boundary regex for normal text, but simple contains for spaced text
        word_regex = Regexp.new("\\b#{Regexp.escape(spam_word_str)}\\b", Regexp::IGNORECASE)
        if word_regex.match?(reverse_normalized) ||
           word_regex.match?(collapsed_text) ||
           (spam_word_str.length >= 4 && spaced_text.include?(spam_word_str)) # Minimum 4 chars for spaced text
          return true
        end

        # Also check spam words with spaces removed against the text
        spam_word_no_spaces = spam_word_str.gsub(/\s+/, "")
        next unless spam_word_no_spaces.length >= 4 && spam_word_no_spaces != spam_word_str

        no_space_regex = Regexp.new("\\b#{Regexp.escape(spam_word_no_spaces)}\\b", Regexp::IGNORECASE)
        if no_space_regex.match?(normalized_text) ||
           no_space_regex.match?(reverse_normalized) ||
           no_space_regex.match?(collapsed_text) ||
           spaced_text.include?(spam_word_no_spaces)
          return true
        end
      end

      # Check using cached creative pattern regexes for spam
      CACHED_SPAM_REGEXES.each_value do |regex|
        if debug_logging_enabled?
          # # rails.logger.debug "  DEBUG (spam): checking spam_word = '#{spam_word_str}'"
          match_result_norm = regex.match?(normalized_text)
          # # rails.logger.debug "    DEBUG (spam): normalized_text ('#{normalized_text}') match? #{match_result_norm}"
          if match_result_norm
            # # rails.logger.debug "      MATCHED (spam)! Returning true."
            return true
          end
        end

        return true if regex.match?(normalized_text) || regex.match?(spaced_text) || regex.match?(collapsed_text)
      end
      false
    end

    # Check for other suspicious content
    def contains_suspicious_content?(text)
      return false if text.blank?

      # Ensure UTF-8 encoding
      text = ensure_utf8_encoding(text)

      SUSPICIOUS_PATTERNS.any? { |pattern| pattern.match?(text) }
    end

    # Get specific violation details for logging/debugging
    def get_violation_details(text)
      return [] if text.blank?

      # Ensure UTF-8 encoding
      text = ensure_utf8_encoding(text)

      violations = []

      if contains_profanity?(text)
        violated_words = []
        normalized_text = text.to_ascii.downcase
                              .gsub(/['']/, "'")  # Replace curly apostrophes with straight ones
                              .gsub(/[""]/, '"')  # Replace curly quotes with straight ones
                              .gsub(/[–—]/, "-")  # Replace en/em dashes with hyphens
        spaced_text = normalized_text.gsub(/[_\-.\s]/, "")
        collapsed_text = normalized_text.gsub(/(.)\1+/, '\1')

        # Check for creative pattern matches using cached regexes
        CACHED_PROFANITY_REGEXES.each do |bad_word_str, regex|
          if (match_data = regex.match(normalized_text))
            violated_words << "#{match_data[0]} (creative match for: #{bad_word_str})"
          elsif (match_data = regex.match(spaced_text))
            violated_words << "#{match_data[0]} (spaced creative match for: #{bad_word_str})"
          elsif (match_data = regex.match(collapsed_text))
            violated_words << "#{match_data[0]} (collapsed creative match for: #{bad_word_str})"
          end
        end

        violations << { type: "profanity", details: violated_words.uniq }
      end

      index = 0
      while index < PII_PATTERNS.length
        pattern = PII_PATTERNS[index]
        violations << { type: "pii", pattern_index: index, pattern_type: pii_pattern_type(index) } if pattern.match?(text)
        index += 1
      end

      index = 0
      while index < SPAM_PATTERNS.length
        pattern = SPAM_PATTERNS[index]
        violations << { type: "spam", pattern_index: index, pattern_type: spam_pattern_type(index) } if pattern.match?(text)
        index += 1
      end

      # Check spam words with creative patterns
      if contains_spam?(text)
        violated_spam_words = []
        normalized_text = text.to_ascii.downcase
                              .gsub(/['']/, "'")  # Replace curly apostrophes with straight ones
                              .gsub(/[""]/, '"')  # Replace curly quotes with straight ones
                              .gsub(/[–—]/, "-")  # Replace en/em dashes with hyphens
        spaced_text = normalized_text.gsub(/[_\-.\s]/, "")
        collapsed_text = normalized_text.gsub(/(.)\1+/, '\1')

        CACHED_SPAM_REGEXES.each do |spam_word_str, regex|
          if (match_data = regex.match(normalized_text))
            violated_spam_words << "#{match_data[0]} (creative match for: #{spam_word_str})"
          elsif (match_data = regex.match(spaced_text))
            violated_spam_words << "#{match_data[0]} (spaced creative match for: #{spam_word_str})"
          elsif (match_data = regex.match(collapsed_text))
            violated_spam_words << "#{match_data[0]} (collapsed creative match for: #{spam_word_str})"
          end
        end

        violations << { type: "spam", details: violated_spam_words.uniq } if violated_spam_words.any?
      end

      index = 0
      while index < SUSPICIOUS_PATTERNS.length
        pattern = SUSPICIOUS_PATTERNS[index]
        violations << { type: "suspicious", pattern_index: index, pattern_type: suspicious_pattern_type(index) } if pattern.match?(text)
        index += 1
      end

      violations
    end

    private

    # Helper method to ensure text is properly encoded as UTF-8
    def ensure_utf8_encoding(text)
      return text if text.nil?

      # Convert to string if not already
      text = text.to_s

      # If already UTF-8 and valid, return as is
      return text if text.encoding == Encoding::UTF_8 && text.valid_encoding?

      # Try to force UTF-8 encoding
      begin
        # First try to encode to UTF-8 from current encoding
        text.encode(Encoding::UTF_8)
      rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
        # If that fails, force encoding and replace invalid bytes
        text.force_encoding(Encoding::UTF_8)
        unless text.valid_encoding?
          # Replace invalid UTF-8 sequences with replacement character
          text = text.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: "?")
        end
        text
      end
    end

    def pii_pattern_type(index)
      types = %w[email phone credit_card ssn ip_address postal_code]
      types[index] || "unknown_pii_#{index}"
    end

    def spam_pattern_type(index)
      types = %w[multiple_urls excessive_caps excessive_exclamation character_repetition spam_phrases urgent_phrases]
      types[index] || "unknown_spam_#{index}"
    end

    def suspicious_pattern_type(index)
      types = %w[excessive_symbols base64_like] # Removed mixed_character_sets as it wasn't defined
      types[index] || "unknown_suspicious_#{index}"
    end
  end
end
