# frozen_string_literal: true
# shareable_constant_value: literal

require "test_helper"

class VectorizationServiceTest < ActiveSupport::TestCase
  setup do
    # Clear caches before each test
    Rails.cache.delete("search_vocabulary")
    Rails.cache.delete("document_frequencies")

    # Temporarily disable moderation for tests
    @original_moderation_setting = InstanceSetting.get("automoderation_enabled")
    InstanceSetting.set("automoderation_enabled", "false", "Temporarily disable moderation for tests")

    # Create test experiences
    @experience1 = Experience.create!(
      title: "Machine Learning Basics",
      description: "Introduction to machine learning algorithms and concepts",
      author: "John Doe",
      account: accounts(:one)
    )

    @experience2 = Experience.create!(
      title: "Deep Learning Neural Networks",
      description: "Advanced neural network architectures for deep learning",
      author: "Jane Smith",
      account: accounts(:two)
    )

    @experience3 = Experience.create!(
      title: "Cooking Pasta",
      description: "How to cook perfect pasta every time",
      author: "Chef Mario",
      account: accounts(:one)
    )
  end

  test "generates vocabulary from experiences" do
    vocabulary = VectorizationService.current_vocabulary

    assert vocabulary.is_a?(Array)
    assert vocabulary.length.positive?

    # Should contain terms from our test experiences
    vocabulary_text = vocabulary.join(" ")
    assert_includes vocabulary_text, "machine"
    assert_includes vocabulary_text, "learning"
    assert_includes vocabulary_text, "neural"
  end

  test "vectorizes experience correctly" do
    vocabulary = VectorizationService.current_vocabulary
    vector = VectorizationService.vectorize_experience(@experience1, vocabulary)

    assert vector.is_a?(Array)
    assert_equal vocabulary.length, vector.length

    # Vector should contain non-zero values for relevant terms
    machine_index = vocabulary.index("machine")
    learning_index = vocabulary.index("learning")

    if machine_index && learning_index
      assert vector[machine_index].positive?, "Should have positive value for 'machine'"
      assert vector[learning_index].positive?, "Should have positive value for 'learning'"
    end
  end

  test "vectorizes query correctly" do
    vocabulary = VectorizationService.current_vocabulary
    query_vector = VectorizationService.vectorize_query("machine learning", vocabulary)

    assert query_vector.is_a?(Array)
    assert_equal vocabulary.length, query_vector.length

    # Should have non-zero values for query terms
    machine_index = vocabulary.index("machine")
    learning_index = vocabulary.index("learning")

    if machine_index && learning_index
      assert query_vector[machine_index].positive?
      assert query_vector[learning_index].positive?
    end
  end

  test "handles empty query gracefully" do
    vocabulary = VectorizationService.current_vocabulary
    vector = VectorizationService.vectorize_query("", vocabulary)

    assert vector.is_a?(Array)
    assert_equal vocabulary.length, vector.length
    assert vector.all? { |v| v == 0.0 }, "Empty query should produce zero vector"
  end

  test "handles experience without content gracefully" do
    empty_experience = Experience.create!(
      title: "Empty",
      description: "",
      author: "",
      account: accounts(:one)
    )

    vocabulary = VectorizationService.current_vocabulary
    vector = VectorizationService.vectorize_experience(empty_experience, vocabulary)

    assert vector.is_a?(Array)
    assert_equal vocabulary.length, vector.length
  end

  test "caches vocabulary correctly" do
    # First call should calculate vocabulary
    vocab1 = VectorizationService.current_vocabulary

    # Second call should use cached version
    vocab2 = VectorizationService.current_vocabulary

    assert_equal vocab1, vocab2

    # Cache key should exist
    cached_vocab = Rails.cache.read("search_vocabulary")
    assert_not_nil cached_vocab
    assert_equal vocab1, cached_vocab
  end

  test "refreshes vocabulary when requested" do
    # Get initial vocabulary
    VectorizationService.current_vocabulary

    # Add new experience with unique terms
    Experience.create!(
      title: "Quantum Computing Fundamentals",
      description: "Quantum algorithms and qubit manipulation",
      author: "Quantum Expert",
      account: accounts(:one)
    )

    # Refresh vocabulary
    new_vocab = VectorizationService.refresh_vocabulary

    # Should contain new terms
    new_vocab_text = new_vocab.join(" ")
    assert_includes new_vocab_text, "quantum"
    assert_includes new_vocab_text, "qubit"
  end

  test "applies field weights correctly" do
    # Create experience with distinctive terms in different fields
    test_exp = Experience.create!(
      title: "TitleTerm",
      description: "DescriptionTerm content here",
      author: "AuthorTerm",
      account: accounts(:one)
    )

    vocabulary = %w[titleterm descriptionterm authorterm]
    vector = VectorizationService.vectorize_experience(test_exp, vocabulary)

    title_index = vocabulary.index("titleterm")
    desc_index = vocabulary.index("descriptionterm")
    author_index = vocabulary.index("authorterm")

    # Title should have highest weight (3.0)
    # Description should have medium weight (2.0)
    # Author should have lowest weight (1.0)
    if title_index && desc_index && author_index
      assert vector[title_index] > vector[desc_index], "Title should have higher weight than description"
      assert vector[desc_index] > vector[author_index], "Description should have higher weight than author"
    end
  end

  test "generates consistent vectors for same content" do
    vocabulary = VectorizationService.current_vocabulary

    vector1 = VectorizationService.vectorize_experience(@experience1, vocabulary)
    vector2 = VectorizationService.vectorize_experience(@experience1, vocabulary)

    assert_equal vector1, vector2, "Same experience should generate identical vectors"
  end

  test "generates different vectors for different content" do
    vocabulary = VectorizationService.current_vocabulary

    vector1 = VectorizationService.vectorize_experience(@experience1, vocabulary)
    vector2 = VectorizationService.vectorize_experience(@experience3, vocabulary)

    assert_not_equal vector1, vector2, "Different experiences should generate different vectors"
  end

  test "handles special characters and punctuation" do
    special_exp = Experience.create!(
      title: "Test with @#$%^&*() symbols!",
      description: "Content with 'quotes' and \"double quotes\" and numbers 123",
      author: "Author-Name_With.Dots",
      account: accounts(:one)
    )

    vocabulary = VectorizationService.current_vocabulary
    vector = VectorizationService.vectorize_experience(special_exp, vocabulary)

    assert vector.is_a?(Array)
    assert_equal vocabulary.length, vector.length
    assert vector.any?(&:positive?), "Should extract some meaningful terms"
  end

  test "normalizes text case consistently" do
    upper_exp = Experience.create!(
      title: "MACHINE LEARNING",
      description: "UPPERCASE CONTENT",
      author: "UPPERCASE AUTHOR",
      account: accounts(:one)
    )

    lower_exp = Experience.create!(
      title: "machine learning",
      description: "lowercase content",
      author: "lowercase author",
      account: accounts(:two)
    )

    vocabulary = VectorizationService.current_vocabulary
    upper_vector = VectorizationService.vectorize_experience(upper_exp, vocabulary)
    lower_vector = VectorizationService.vectorize_experience(lower_exp, vocabulary)

    # Find relevant indices
    machine_index = vocabulary.index("machine")
    learning_index = vocabulary.index("learning")

    if machine_index && learning_index
      # Should have similar values regardless of case
      assert_in_delta upper_vector[machine_index], lower_vector[machine_index], 0.1
      assert_in_delta upper_vector[learning_index], lower_vector[learning_index], 0.1
    end
  end

  teardown do
    # Clean up created experiences
    Experience.where.not(id: [ experiences(:one).id, experiences(:two).id ]).delete_all
    Rails.cache.delete("search_vocabulary")
    Rails.cache.delete("document_frequencies")

    # Restore original moderation setting
    InstanceSetting.set("automoderation_enabled", @original_moderation_setting || "true", "Restore moderation setting") if defined?(@original_moderation_setting)
  end
end
