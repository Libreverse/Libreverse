# frozen_string_literal: true

require "test_helper"

class VectorSimilarityServiceTest < ActiveSupport::TestCase
  setup do
    # Temporarily disable moderation for tests
    @original_moderation_setting = InstanceSetting.get("automoderation_enabled")
    InstanceSetting.set("automoderation_enabled", "false", "Temporarily disable moderation for tests")

    # Create test vectors
    @vector_a = [ 1.0, 2.0, 3.0, 4.0 ]
    @vector_b = [ 2.0, 4.0, 6.0, 8.0 ] # Proportional to vector_a
    @vector_c = [ 1.0, 0.0, 0.0, 0.0 ] # Orthogonal to vector_a
    @zero_vector = [ 0.0, 0.0, 0.0, 0.0 ]
    @unit_vector = [ 1.0, 0.0, 0.0, 0.0 ]
  end

  test "calculates cosine similarity correctly for identical vectors" do
    similarity = VectorSimilarityService.cosine_similarity(@vector_a, @vector_a)
    assert_in_delta 1.0, similarity, 0.001
  end

  test "calculates cosine similarity correctly for proportional vectors" do
    similarity = VectorSimilarityService.cosine_similarity(@vector_a, @vector_b)
    assert_in_delta 1.0, similarity, 0.001
  end

  test "calculates cosine similarity correctly for orthogonal vectors" do
    similarity = VectorSimilarityService.cosine_similarity(@vector_a, @vector_c)
    assert_in_delta 0.183, similarity, 0.01 # cos(angle) for these vectors
  end

  test "returns zero for zero vectors" do
    similarity = VectorSimilarityService.cosine_similarity(@zero_vector, @vector_a)
    assert_equal 0.0, similarity
  end

  test "returns zero for nil vectors" do
    similarity = VectorSimilarityService.cosine_similarity(nil, @vector_a)
    assert_equal 0.0, similarity

    similarity = VectorSimilarityService.cosine_similarity(@vector_a, nil)
    assert_equal 0.0, similarity
  end

  test "returns zero for empty vectors" do
    similarity = VectorSimilarityService.cosine_similarity([], @vector_a)
    assert_equal 0.0, similarity
  end

  test "returns zero for mismatched vector lengths" do
    short_vector = [ 1.0, 2.0 ]
    similarity = VectorSimilarityService.cosine_similarity(@vector_a, short_vector)
    assert_equal 0.0, similarity
  end

  test "calculates vector magnitude correctly" do
    magnitude = VectorSimilarityService.vector_magnitude(@vector_a)
    expected = Math.sqrt(1.0 + 4.0 + 9.0 + 16.0) # sqrt(30)
    assert_in_delta expected, magnitude, 0.001
  end

  test "calculates zero magnitude for empty vector" do
    magnitude = VectorSimilarityService.vector_magnitude([])
    assert_equal 0.0, magnitude
  end

  test "normalizes vector correctly" do
    normalized = VectorSimilarityService.normalize_vector(@vector_a)
    magnitude = VectorSimilarityService.vector_magnitude(normalized)
    assert_in_delta 1.0, magnitude, 0.001
  end

  test "handles zero vector normalization" do
    normalized = VectorSimilarityService.normalize_vector(@zero_vector)
    assert_equal @zero_vector, normalized
  end

  test "calculates euclidean distance correctly" do
    distance = VectorSimilarityService.euclidean_distance(@vector_a, @vector_b)
    # Distance between [1,2,3,4] and [2,4,6,8] = sqrt((1-2)^2 + (2-4)^2 + (3-6)^2 + (4-8)^2)
    expected = Math.sqrt(1 + 4 + 9 + 16) # sqrt(30)
    assert_in_delta expected, distance, 0.001
  end

  test "calculates manhattan distance correctly" do
    distance = VectorSimilarityService.manhattan_distance(@vector_a, @vector_b)
    # Distance between [1,2,3,4] and [2,4,6,8] = |1-2| + |2-4| + |3-6| + |4-8|
    expected = 1 + 2 + 3 + 4 # 10
    assert_equal expected, distance
  end

  test "returns infinity for mismatched vector lengths in distance calculations" do
    short_vector = [ 1.0, 2.0 ]

    euclidean = VectorSimilarityService.euclidean_distance(@vector_a, short_vector)
    assert_equal Float::INFINITY, euclidean

    manhattan = VectorSimilarityService.manhattan_distance(@vector_a, short_vector)
    assert_equal Float::INFINITY, manhattan
  end

  test "finds similar experiences with vector search" do
    # Create test experiences with vectors
    experience1 = experiences(:one)
    experience2 = experiences(:two)

    # Create experience vectors
    ExperienceVector.create!(
      experience: experience1,
      vector_data: @vector_a,
      vector_hash: "hash1",
      generated_at: Time.current,
      version: 1
    )

    ExperienceVector.create!(
      experience: experience2,
      vector_data: @vector_b,
      vector_hash: "hash2",
      generated_at: Time.current,
      version: 1
    )

    query_vector = @vector_a
    results = VectorSimilarityService.find_similar_experiences(
      query_vector,
      Experience.all,
      limit: 10,
      threshold: 0.5
    )

    assert results.is_a?(Array)
    assert results.length <= 2

    # Should find both experiences since vectors are similar
    found_experiences = results.map { |r| r[:experience] }
    assert_includes found_experiences, experience1
    assert_includes found_experiences, experience2

    # Results should be sorted by similarity
    assert results.first[:similarity] >= results.last[:similarity] if results.length > 1
  end

  test "finds similar experiences to a target experience" do
    experience1 = experiences(:one)
    experience2 = experiences(:two)

    # Create experience vectors
    ExperienceVector.create!(
      experience: experience1,
      vector_data: @vector_a,
      vector_hash: "hash1",
      generated_at: Time.current,
      version: 1
    )

    ExperienceVector.create!(
      experience: experience2,
      vector_data: @vector_b,
      vector_hash: "hash2",
      generated_at: Time.current,
      version: 1
    )

    results = VectorSimilarityService.find_similar_to_experience(
      experience1,
      limit: 5,
      threshold: 0.5
    )

    assert results.is_a?(Array)
    # Should not include the target experience itself
    found_experiences = results.map { |r| r[:experience] }
    assert_not_includes found_experiences, experience1
    assert_includes found_experiences, experience2
  end

  test "returns empty array when no vector exists for target experience" do
    experience = experiences(:one)
    # No vector created for this experience

    results = VectorSimilarityService.find_similar_to_experience(
      experience,
      limit: 5,
      threshold: 0.5
    )

    assert_equal [], results
  end

  test "filters results by similarity threshold" do
    experience1 = experiences(:one)
    experience2 = experiences(:two)

    # Create vectors with very different similarity
    ExperienceVector.create!(
      experience: experience1,
      vector_data: @vector_a,
      vector_hash: "hash1",
      generated_at: Time.current,
      version: 1
    )

    ExperienceVector.create!(
      experience: experience2,
      vector_data: @vector_c, # Very different vector
      vector_hash: "hash2",
      generated_at: Time.current,
      version: 1
    )

    # High threshold should filter out dissimilar results
    results = VectorSimilarityService.find_similar_experiences(
      @vector_a,
      Experience.all,
      limit: 10,
      threshold: 0.9
    )

    # Only the very similar experience should be found
    assert results.length <= 1
    assert results.first[:similarity] > 0.9 if results.any?
  end

  test "respects limit parameter" do
    # Create multiple experiences with vectors
    experiences = []
    3.times do |i|
      exp = Experience.create!(
        title: "Test Experience #{i}",
        description: "Test description #{i}",
        author: "Test Author",
        account: accounts(:one)
      )

      ExperienceVector.create!(
        experience: exp,
        vector_data: @vector_a.map { |v| v + i * 0.1 }, # Slightly different vectors
        vector_hash: "hash#{i}",
        generated_at: Time.current,
        version: 1
      )

      experiences << exp
    end

    results = VectorSimilarityService.find_similar_experiences(
      @vector_a,
      Experience.all,
      limit: 2,
      threshold: 0.01
    )

    assert results.length <= 2
  end

  teardown do
    # Clean up created records
    ExperienceVector.delete_all
    
    # Restore original moderation setting
    InstanceSetting.set("automoderation_enabled", @original_moderation_setting || "true", "Restore moderation setting") if defined?(@original_moderation_setting)
  end
end
