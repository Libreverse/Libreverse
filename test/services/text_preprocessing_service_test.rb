require "English"
require "test_helper"

class TextPreprocessingServiceTest < ActiveSupport::TestCase
  test "converts text to lowercase" do
    result = TextPreprocessingService.preprocess("HELLO WORLD")
    assert(result.all? { |term| term == term.downcase })
  end

  test "removes punctuation and special characters" do
    result = TextPreprocessingService.preprocess("Hello, world! How are you?")

    # Should not contain punctuation
    flattened = result.join(" ")
    assert_not_includes flattened, ","
    assert_not_includes flattened, "!"
    assert_not_includes flattened, "?"
  end

  test "filters out common stop words" do
    result = TextPreprocessingService.preprocess("the quick brown fox")

    # "the" is a common stop word and should be filtered
    assert_not_includes result, "the"
    assert_includes result, "quick"
    assert_includes result, "brown"
    assert_includes result, "fox"
  end

  test "filters out very short words" do
    result = TextPreprocessingService.preprocess("a big elephant")

    # Single letters should be filtered
    assert_not_includes result, "a"
    assert_includes result, "big"
    assert_includes result, "elephant"
  end

  test "handles empty and nil input" do
    assert_equal [], TextPreprocessingService.preprocess("")
    assert_equal [], TextPreprocessingService.preprocess(nil)
    assert_equal [], TextPreprocessingService.preprocess("   ")
  end

  test "handles numbers appropriately" do
    result = TextPreprocessingService.preprocess("machine learning 101")

    # Should include meaningful numbers
    result.join(" ")
    # Implementation may vary on how numbers are handled
    assert result.length.positive?
  end

  test "handles special characters and symbols" do
    result = TextPreprocessingService.preprocess("C++ programming & Python @home")

    # Should extract meaningful terms despite special characters
    processed_text = result.join(" ")
    assert_includes processed_text, "programming"
    assert_includes processed_text, "python"
    assert_includes processed_text, "home"
  end

  test "preserves meaningful compound words" do
    result = TextPreprocessingService.preprocess("machine-learning artificial_intelligence")

    # Should handle hyphenated and underscored terms appropriately
    processed_text = result.join(" ")
    assert processed_text.include?("machine") || processed_text.include?("learning")
    assert processed_text.include?("artificial") || processed_text.include?("intelligence")
  end

  test "handles unicode and international characters" do
    result = TextPreprocessingService.preprocess("café naïve résumé piñata")

    # Should handle accented characters appropriately
    assert result.length.positive?
    processed_text = result.join(" ")
    # May normalize to ascii or preserve unicode depending on implementation
    assert_includes processed_text, "caf"
    assert_includes processed_text, "sum" # "résumé" may be processed as "sum"
  end

  test "processes long text efficiently" do
    long_text = "machine learning " * 1000 # Very long text

    start_time = Time.current
    result = TextPreprocessingService.preprocess(long_text)
    end_time = Time.current

    # Should complete quickly even with long text
    assert (end_time - start_time) < 1.second
    assert result.length.positive?
  end

  test "handles HTML and markup text" do
    html_text = "<h1>Machine Learning</h1><p>This is a <strong>tutorial</strong></p>"
    result = TextPreprocessingService.preprocess(html_text)

    processed_text = result.join(" ")

    # Should extract text content, ignore HTML tags
    assert_includes processed_text, "machine"
    assert_includes processed_text, "learning"
    assert_includes processed_text, "tutorial"
    assert_not_includes processed_text, "<h1>"
    assert_not_includes processed_text, "</h1>"
  end

  test "normalizes whitespace" do
    messy_text = "machine    learning\t\nartificial     intelligence"
    result = TextPreprocessingService.preprocess(messy_text)

    # Should handle multiple spaces, tabs, newlines
    processed_text = result.join(" ")
    assert_includes processed_text, "machine"
    assert_includes processed_text, "learning"
    assert_includes processed_text, "artificial"
    assert_includes processed_text, "intelligence"
  end

  test "applies stemming or lemmatization consistently" do
    # Test words with different forms
    result1 = TextPreprocessingService.preprocess("running runs ran")
    result2 = TextPreprocessingService.preprocess("running runs ran")

    # Results should be consistent
    assert_equal result1, result2

    # May reduce to root forms depending on implementation
    processed_text = result1.join(" ")
    assert processed_text.length.positive?
  end

  test "handles mixed case consistently" do
    result1 = TextPreprocessingService.preprocess("Machine Learning")
    result2 = TextPreprocessingService.preprocess("MACHINE LEARNING")
    result3 = TextPreprocessingService.preprocess("machine learning")

    # All should produce the same result
    assert_equal result1, result2
    assert_equal result2, result3
  end

  test "preserves meaningful technical terms" do
    technical_text = "JavaScript Python C++ API REST JSON XML HTTP"
    result = TextPreprocessingService.preprocess(technical_text)

    processed_text = result.join(" ")

    # Should preserve important technical terms
    assert_includes processed_text, "javascript"
    assert_includes processed_text, "python"
    assert_includes processed_text, "api"
    assert_includes processed_text, "rest"
    assert_includes processed_text, "json"
  end

  test "handles edge cases gracefully" do
    edge_cases = [
      "!!!@@@###{$PROCESS_ID}$%%%", # Only special characters
      "123 456 789",       # Only numbers
      "a b c d e f",       # Only short words
      "THE AND OR BUT",    # Only stop words
      "",                  # Empty string
      "   \t\n   " # Only whitespace
    ]

    edge_cases.each do |text|
      assert_nothing_raised do
        result = TextPreprocessingService.preprocess(text)
        assert result.is_a?(Array)
      end
    end
  end

  test "returns consistent data types" do
    inputs = [
      "normal text",
      "",
      nil,
      "text with 123 numbers",
      "UPPERCASE TEXT"
    ]

    inputs.each do |input|
      result = TextPreprocessingService.preprocess(input)
      assert result.is_a?(Array)
      assert(result.all? { |item| item.is_a?(String) })
    end
  end
end
