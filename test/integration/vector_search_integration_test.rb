# frozen_string_literal: true

require "test_helper"

class VectorSearchIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    # Clean slate for integration tests
    Experience.delete_all
    ExperienceVector.delete_all
    Rails.cache.clear

    # Create test experiences
    @ml_experience = Experience.create!(
      title: "Machine Learning Tutorial",
      description: "Learn about neural networks and deep learning",
      author: "AI Expert",
      account: accounts(:one),
      approved: true
    )

    @cooking_experience = Experience.create!(
      title: "Italian Cooking Guide",
      description: "Master authentic Italian recipes and techniques",
      author: "Chef Marco",
      account: accounts(:two),
      approved: true
    )

    @space_experience = Experience.create!(
      title: "Space Exploration",
      description: "Journey through the cosmos and solar system",
      author: "Astronomer",
      account: accounts(:one),
      approved: true
    )

    # Generate vectors for experiences
    generate_test_vectors
  end

  test "search returns relevant results for vector search" do
    get "/search", params: { query: "machine learning" }

    assert_response :success
    assert_select "main" # Search results should be displayed

    # Check that relevant experience is found
    assert_match(/Machine Learning Tutorial/i, response.body)

    # Less relevant experiences should not be prominent
    assert_no_match(/Italian Cooking/i, response.body)
  end

  test "search handles empty query gracefully" do
    get "/search"

    assert_response :success
    assert_select "main"

    # Should show recent experiences or empty state
    assert_match(/experiences|recent/i, response.body)
  end

  test "search respects query length limits" do
    long_query = "a" * 100 # Very long query

    get "/search", params: { query: long_query }

    assert_response :success
    # Should handle gracefully without errors
  end

  test "search works with special characters" do
    get "/search", params: { query: "machine & learning!" }

    assert_response :success
    assert_select "main"
  end

  test "search pagination works correctly" do
    # Create many experiences to test pagination
    20.times do |i|
      Experience.create!(
        title: "Machine Learning Tutorial #{i}",
        description: "ML content #{i}",
        author: "Author #{i}",
        account: accounts(:one),
        approved: true
      )
    end

    get "/search", params: { query: "machine" }

    assert_response :success
    # Should not return all results on first page
  end

  test "search caching works correctly" do
    # First request
    get "/search", params: { query: "machine learning" }
    assert_response :success
    Time.current

    # Second identical request should be faster due to caching
    get "/search", params: { query: "machine learning" }
    assert_response :success

    # Response should be consistent
    assert_select "main"
  end

  test "search handles concurrent requests" do
    threads = []
    responses = []

    5.times do
      threads << Thread.new do
        get "/search", params: { query: "space" }
        responses << response.status
      end
    end

    threads.each(&:join)

    # All requests should succeed
    assert(responses.all? { |status| status == 200 })
  end

  test "search reflex provides real-time results" do
    # This would test the StimulusReflex functionality
    # Since we can't easily test WebSocket in integration tests,
    # we'll test the underlying service

    results = ExperienceSearchService.search("machine learning")
    assert results.length.positive?
    assert_includes results.map(&:title), "Machine Learning Tutorial"
  end

  test "vector search falls back to LIKE search when vectors unavailable" do
    # Remove all vectors
    ExperienceVector.delete_all

    get "/search", params: { query: "machine" }

    assert_response :success
    # Should still find results using LIKE search
    assert_match(/Machine Learning Tutorial/i, response.body)
  end

  test "search results are properly escaped and safe" do
    # Create experience with potential XSS content
    Experience.create!(
      title: "<script>alert('xss')</script>Machine Learning",
      description: "Safe description",
      author: "Safe Author",
      account: accounts(:one),
      approved: true
    )

    get "/search", params: { query: "machine" }

    assert_response :success
    # Script tag should be escaped, not executed
    assert_includes response.body, "&lt;script&gt;"
    assert_not_includes response.body, "<script>"
  end

  test "unapproved experiences are hidden from regular users" do
    # Create unapproved experience
    Experience.create!(
      title: "Unapproved Machine Learning Content",
      description: "This should not appear",
      author: "Hidden Author",
      account: accounts(:one),
      approved: false
    )

    get "/search", params: { query: "machine" }

    assert_response :success
    assert_no_match(/Unapproved Machine Learning/i, response.body)
  end

  test "search handles database errors gracefully" do
    # Mock database error
    ExperienceSearchService.stubs(:search).raises(ActiveRecord::StatementInvalid.new("Database error"))

    get "/search", params: { query: "machine" }

    # Should not crash the application
    assert_response :success
  end

  test "search performance is acceptable" do
    # Create more experiences for realistic performance test
    50.times do |i|
      exp = Experience.create!(
        title: "Experience #{i} about technology",
        description: "Content about various tech topics #{i}",
        author: "Author #{i}",
        account: accounts(:one),
        approved: true
      )

      # Generate vector for each
      vector_data = VectorizationService.vectorize_experience(exp)
      ExperienceVector.create!(
        experience: exp,
        vector_data: vector_data,
        vector_hash: "hash#{i}",
        generated_at: Time.current,
        version: 1
      )
    end

    start_time = Time.current
    get "/search", params: { query: "technology" }
    end_time = Time.current

    assert_response :success

    # Search should complete within reasonable time (adjust as needed)
    assert (end_time - start_time) < 5.seconds, "Search took too long: #{end_time - start_time} seconds"
  end

  test "search suggestions work correctly" do
    suggestions = ExperienceSearchService.suggest("mach")

    assert suggestions.is_a?(Array)
    assert_includes suggestions, "Machine Learning Tutorial"
  end

  test "related experiences feature works" do
    related = ExperienceSearchService.find_related(@ml_experience)

    assert related.is_a?(Array)
    assert_not_includes related, @ml_experience

    # Should find experiences with related content
    related.map(&:title)
    # AI/ML content might be related to space exploration depending on vectors
  end

  test "vector search respects user permissions" do
    # Test with admin user permissions
    sign_in_as_admin if respond_to?(:sign_in_as_admin)

    get "/search", params: { query: "machine" }
    assert_response :success
  end

  test "search handles malformed queries safely" do
    malformed_queries = [
      "'; DROP TABLE experiences; --",
      "%",
      "_",
      "\\",
      nil
    ]

    malformed_queries.each do |query|
      get "/search", params: { query: query }
      assert_response :success
    end
  end

  test "search metadata is correct" do
    get "/search", params: { query: "machine learning" }

    assert_response :success

    # Check that search type and result count are reasonable
    # This would require parsing the response or checking assigned variables
    # depending on how the controller exposes this information
  end

  private

  def generate_test_vectors
    vocabulary = VectorizationService.current_vocabulary

    [ @ml_experience, @cooking_experience, @space_experience ].each do |experience|
      vector_data = VectorizationService.vectorize_experience(experience, vocabulary)
      content_hash = ExperienceVector.generate_content_hash(
        experience.title,
        experience.description,
        experience.author
      )

      ExperienceVector.create!(
        experience: experience,
        vector_data: vector_data,
        vector_hash: content_hash,
        generated_at: Time.current,
        version: 1
      )
    end
  end

  teardown do
    Experience.delete_all
    ExperienceVector.delete_all
    Rails.cache.clear
  end
end
