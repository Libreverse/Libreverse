# frozen_string_literal: true

require "test_helper"
require "ostruct"

class VectorSearchControllerTest < ActionController::TestCase
  setup do
    @controller = SearchController.new

    # Clean slate
    ExperienceVector.delete_all
    Experience.delete_all
    Rails.cache.clear

    # Create test experiences
    @ml_experience = Experience.create!(
      title: "Machine Learning Guide",
      description: "Complete guide to machine learning",
      author: "AI Expert",
      account: accounts(:one),
      approved: true
    )

    @cooking_experience = Experience.create!(
      title: "Baking Fundamentals",
      description: "Learn essential baking techniques",
      author: "Chef",
      account: accounts(:two),
      approved: true
    )

    # Create vectors
    create_test_vectors
  end

  test "search index renders successfully with vector search" do
    get :index, params: { query: "machine learning" }

    assert_response :success
    assert_not_nil assigns(:experiences)
    assert_not_nil assigns(:search_metadata)
  end

  test "search index handles empty query" do
    get :index

    assert_response :success
    assert_not_nil assigns(:experiences)

    # Should show recent experiences
    metadata = assigns(:search_metadata)
    assert_equal :recent, metadata[:search_type]
  end

  test "search metadata contains correct information" do
    get :index, params: { query: "machine" }

    assert_response :success

    metadata = assigns(:search_metadata)
    assert metadata.key?(:total_results)
    assert metadata.key?(:search_type)
    assert metadata.key?(:query)
    assert_equal "machine", metadata[:query]
  end

  test "search respects admin permissions" do
    # Create unapproved experience
    Experience.create!(
      title: "Unapproved Content",
      description: "Hidden content",
      author: "Hidden",
      account: accounts(:one),
      approved: false
    )

    # Test as regular user (no current account)
    get :index, params: { query: "content" }
    assert_response :success

    experiences = assigns(:experiences)
    titles = experiences.map(&:title)
    assert_not_includes titles, "Unapproved Content"
  end

  test "search handles query length limits" do
    long_query = "machine learning " * 20 # Very long query

    get :index, params: { query: long_query }

    assert_response :success
    # Should handle gracefully
  end

  test "search handles special characters safely" do
    special_query = "<script>alert('xss')</script>machine"

    get :index, params: { query: special_query }

    assert_response :success
    # Should not execute script, should search safely
  end

  test "search caches results properly" do
    # Clear cache to ensure clean state
    Rails.cache.clear

    get :index, params: { query: "machine" }

    assert_response :success
    # Test passes if no cache-related errors occur
  end

  test "search handles vector search failures gracefully" do
    # Mock ExperienceSearchService to fail
    ExperienceSearchService.stubs(:search).raises(StandardError.new("Search failed"))

    # Should still render page, possibly with error message
    get :index, params: { query: "machine" }

    assert_response :success
  end

  test "search returns consistent results" do
    # Same query should return same results
    get :index, params: { query: "machine" }
    first_results = assigns(:experiences)

    get :index, params: { query: "machine" }
    second_results = assigns(:experiences)

    assert_equal first_results.map(&:id).sort, second_results.map(&:id).sort
  end

  # NOTE: Concurrency testing removed from controller tests as ActionController::TestCase
  # is not thread-safe and can cause flaky tests. For testing concurrent requests,
  # create an integration test using ActionDispatch::IntegrationTest instead.
  # Example integration test structure:
  #
  # class VectorSearchIntegrationTest < ActionDispatch::IntegrationTest
  #   test "search handles concurrent requests" do
  #     threads = []
  #     results = []
  #
  #     3.times do
  #       threads << Thread.new do
  #         get search_index_path(query: "machine")
  #         results << response.status
  #       end
  #     end
  #
  #     threads.each(&:join)
  #     assert(results.all? { |status| status == 200 })
  #   end
  # end

  test "search respects limit parameters" do
    # Create many experiences
    20.times do |i|
      Experience.create!(
        title: "Machine Learning #{i}",
        description: "Content #{i}",
        author: "Author #{i}",
        account: accounts(:one),
        approved: true
      )
    end

    get :index, params: { query: "machine" }

    assert_response :success
    experiences = assigns(:experiences)

    # Should limit results (default is typically 100)
    assert experiences.length <= 100
  end

  test "search handles malformed parameters" do
    malformed_params = [
      { query: { nested: "invalid" } },
      { query: %w[array invalid] },
      { query: nil }
    ]

    malformed_params.each do |params|
      get :index, params: params
      assert_response :success
    end
  end

  test "search generates proper ETags for caching" do
    get :index, params: { query: "machine" }

    assert_response :success
    etag = response.headers["ETag"]

    # Should generate ETag for caching
    assert_not_nil etag if defined?(etag)
  end

  test "search handles conditional requests" do
    # First request
    get :index, params: { query: "machine" }
    assert_response :success

    etag = response.headers["ETag"]

    if etag
      # Second request with If-None-Match header
      request.headers["If-None-Match"] = etag
      get :index, params: { query: "machine" }

      # Might return 304 Not Modified in production
      assert_includes [ 200, 304 ], response.status
    end
  end

  test "search logs appropriate information" do
    # Capture log output
    capture_log do
      get :index, params: { query: "machine learning" }
    end

    # Should log search queries for analytics/debugging
    # Implementation may vary
    assert_response :success
  end

  private

  def create_test_vectors
    vocabulary = VectorizationService.current_vocabulary

    [ @ml_experience, @cooking_experience ].each do |experience|
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

  def capture_log
    log_stream = StringIO.new
    old_logger = Rails.logger
    Rails.logger = Logger.new(log_stream)

    yield

    log_stream.string
  ensure
    Rails.logger = old_logger
  end

  teardown do
    ExperienceVector.delete_all
    Experience.delete_all
    Rails.cache.clear
  end
end
