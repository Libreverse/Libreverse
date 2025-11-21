# frozen_string_literal: true
# shareable_constant_value: literal

require "test_helper"

class GraphqlControllerTest < ActionDispatch::IntegrationTest
  def setup
    # Clear any stubs from previous tests
    begin
      GraphqlController.any_instance.unstub(:current_account)
    rescue StandardError
      nil
    end

    # Clear any existing session
    reset_session if respond_to?(:reset_session)

    # Clear cache for tests
    Rails.cache.clear

    # Create a valid Argon2 hash that meets the length requirement (88+ chars)
    valid_hash = "$argon2id$v=19$m=65536,t=1,p=1$dummysaltdummysaltdummysalt$dummyhashdummyhashdummyhashdummyhashdummyhash"

    # Delete any existing accounts first to avoid conflicts
    AccountSequel.where(username: %w[testuser admin]).delete

    @account = AccountSequel.create(
      username: "testuser",
      password_hash: valid_hash,
      status: 2
    )

    @admin_account = AccountSequel.create(
      username: "admin",
      password_hash: valid_hash,
      status: 2,
      admin: true
    )

    # Verify accounts were created successfully
    raise "Failed to create test account: #{@account.inspect}" unless @account.respond_to?(:id)
    raise "Failed to create admin account: #{@admin_account.inspect}" unless @admin_account.respond_to?(:id)

    @experience = Experience.create!(
      title: "Test Experience",
      description: "A test experience",
      author: "Test Author",
      approved: true,
      account_id: @account.id
    )
  end

  def teardown
    Experience.destroy_all
    UserPreference.destroy_all
    ModerationLog.destroy_all
    AccountSequel.where(id: [ @account.id, @admin_account.id ]).delete if @account && @admin_account
  end

  # Helper method to make GraphQL requests
  def graphql_request(query, variables: {}, headers: {})
    post "/graphql",
         params: { query: query, variables: variables }.to_json,
         headers: {
           "Content-Type" => "application/json",
           "Accept" => "application/json"
         }.merge(headers)
  end

  # Helper method to make authenticated GraphQL requests
  def authenticated_graphql_request(account, query, variables: {}, headers: {})
    # Clear any existing stubs first
    begin
      GraphqlController.any_instance.unstub(:current_account)
    rescue StandardError
      nil
    end

    # Stub the current_account method for this request
    GraphqlController.any_instance.stubs(:current_account).returns(account)

    # Make the request
    post "/graphql",
         params: {
           query: query,
           variables: variables
         }.to_json,
         headers: {
           "Content-Type" => "application/json",
           "Accept" => "application/json"
         }.merge(headers)

    # Clear the stub immediately after the request
    begin
      GraphqlController.any_instance.unstub(:current_account)
    rescue StandardError
      nil
    end
  end

  test "authenticated query requires authentication" do
    # Clear any existing session
    reset_session if respond_to?(:reset_session)

    query = <<~GRAPHQL
      {
        me {
          id
          username
        }
      }
    GRAPHQL

    graphql_request(query)
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_not_nil response_data["errors"], "Expected errors but got: #{response_data.inspect}"
    assert_equal "Authentication required", response_data["errors"].first["message"]
  end

  test "public query works without authentication" do
    query = <<~GRAPHQL
      {
        experiences(limit: 5) {
          id
          title
          description
          approved
        }
      }
    GRAPHQL

    graphql_request(query)
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_not_nil response_data["data"]["experiences"]
    assert response_data["data"]["experiences"].is_a?(Array)
  end

  test "authenticated query works with valid session" do
    query = <<~GRAPHQL
      {
        me {
          id
          username
          admin
        }
      }
    GRAPHQL

    authenticated_graphql_request(@account, query)
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_not_nil response_data["data"]["me"]
    assert_equal @account.id.to_s, response_data["data"]["me"]["id"]
    assert_equal @account.username, response_data["data"]["me"]["username"]
    assert_equal false, response_data["data"]["me"]["admin"]
  end

  test "mutation requires CSRF token" do
    mutation = <<~GRAPHQL
      mutation {
        createExperience(title: "New Experience", description: "Test") {
          id
          title
        }
      }
    GRAPHQL

    # Try without CSRF token - enable CSRF checking for this test
    # Need to provide session with account_id but no CSRF token
    post "/graphql",
         params: { query: mutation }.to_json,
         headers: {
           "Content-Type" => "application/json",
           "X-Test-CSRF" => "true" # Enable CSRF checking for this test
         }

    assert_response :forbidden
    response_data = JSON.parse(response.body)
    assert_equal "CSRF token missing or invalid", response_data["errors"].first["message"]
  end

  test "mutation works with valid CSRF token" do
    mutation = <<~GRAPHQL
      mutation {
        createExperience(title: "New Experience", description: "Test", htmlContent: "<p>Test</p>") {
          id
          title
          description
        }
      }
    GRAPHQL

    authenticated_graphql_request(@account, mutation)
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_not_nil response_data["data"]["createExperience"]
    assert_equal "New Experience", response_data["data"]["createExperience"]["title"]
  end

  test "experience queries work correctly" do
    # Test approved experiences query
    query = <<~GRAPHQL
      {
        approvedExperiences(limit: 10) {
          id
          title
          approved
        }
      }
    GRAPHQL

    graphql_request(query)
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_not_nil response_data["data"], "Response should have data: #{response_data.inspect}"
    experiences = response_data["data"]["approvedExperiences"]
    assert_not_nil experiences, "Approved experiences should not be nil"
    assert(experiences.all? { |exp| exp["approved"] == true })
  end

  test "admin can see pending experiences" do
    # Create a pending experience
    pending_exp = Experience.create!(
      title: "Pending Experience",
      description: "Waiting for approval",
      author: "Test Author",
      approved: false,
      account_id: @account.id
    )

    query = <<~GRAPHQL
      {
        pendingApprovalExperiences(limit: 10) {
          id
          title
          approved
        }
      }
    GRAPHQL

    authenticated_graphql_request(@admin_account, query)
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_not_nil response_data["data"], "Response should have data: #{response_data.inspect}"
    experiences = response_data["data"]["pendingApprovalExperiences"]
    assert_not_nil experiences, "Pending approval experiences should not be nil"
    assert(experiences.any? { |exp| exp["id"] == pending_exp.id.to_s })
  end

  test "user preferences work correctly" do
    # Test setting a preference
    mutation = <<~GRAPHQL
      mutation {
        setPreference(key: "theme-selection", value: "dark") {
          key
          value
        }
      }
    GRAPHQL

    authenticated_graphql_request(@account, mutation)
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_equal "theme-selection", response_data["data"]["setPreference"]["key"]
    assert_equal "dark", response_data["data"]["setPreference"]["value"]

    # Test getting the preference
    query = <<~GRAPHQL
      {
        getPreference(key: "theme-selection") {
          key
          value
        }
      }
    GRAPHQL

    authenticated_graphql_request(@account, query)
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_equal "theme-selection", response_data["data"]["getPreference"]["key"]
    assert_equal "dark", response_data["data"]["getPreference"]["value"]
  end

  test "search functionality works" do
    query = <<~GRAPHQL
      {
        searchExperiences(query: "Test", limit: 5) {
          id
          title
        }
      }
    GRAPHQL

    graphql_request(query)
    assert_response :success

    response_data = JSON.parse(response.body)
    experiences = response_data["data"]["searchExperiences"]
    assert(experiences.any? { |exp| exp["title"].include?("Test") })
  end

  test "admin operations require admin privileges" do
    mutation = <<~GRAPHQL
      mutation {
        approveExperience(id: "#{@experience.id}") {
          id
          approved
        }
      }
    GRAPHQL

    # Try as regular user
    authenticated_graphql_request(@account, mutation)
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_not_nil response_data["errors"]
    assert_equal "Admin access required", response_data["errors"].first["message"]

    # Try as admin
    authenticated_graphql_request(@admin_account, mutation)
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_not_nil response_data["data"]["approveExperience"]
    assert_equal true, response_data["data"]["approveExperience"]["approved"]
  end

  test "invalid preference key is rejected" do
    mutation = <<~GRAPHQL
      mutation {
        setPreference(key: "invalid-key", value: "test") {
          key
          value
        }
      }
    GRAPHQL

    authenticated_graphql_request(@account, mutation)
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_not_nil response_data["errors"]
    assert_equal "Invalid preference key", response_data["errors"].first["message"]
  end

  test "moderation logs are accessible" do
    # Create a moderation log
    ModerationLog.create!(
      field: "title",
      model_type: "Experience",
      content: "Bad content",
      reason: "Inappropriate language",
      account_id: @account.id
    )

    query = <<~GRAPHQL
      {
        moderationLogs(limit: 10) {
          id
          field
          modelType
          reason
        }
      }
    GRAPHQL

    authenticated_graphql_request(@account, query)
    assert_response :success

    response_data = JSON.parse(response.body)
    assert_not_nil response_data["data"]["moderationLogs"]
    assert response_data["data"]["moderationLogs"].is_a?(Array)
  end

  test "graphql rate limiting works" do
    # Test the GraphQL controller's built-in rate limiting
    # This tests the apply_rate_limit method in GraphqlController

    # Clear cache to start fresh
    Rails.cache.clear

    # Use a specific IP for this test
    test_ip = "192.168.1.100"

    # Stub the request IP to be consistent across all requests
    ActionDispatch::Request.any_instance.stubs(:ip).returns(test_ip)

    begin
      # Simple query that should work
      query = "{ experiences(limit: 1) { id } }"

      # First, manually set the cache to be close to the limit
      cache_key = "graphql_rate_limit:#{test_ip}"
      Rails.cache.write(cache_key, 99, expires_in: 1.minute)

      # This request should work (count becomes 100)
      graphql_request(query)
      assert_response :success, "First request should succeed"

      # This request should trigger rate limit (count becomes 101)
      graphql_request(query)
      assert_response :too_many_requests, "Second request should be rate limited"

      # Verify the error message
      response_data = JSON.parse(response.body)
      assert_not_nil response_data["errors"], "Response should contain errors"
      assert_equal "Rate limit exceeded", response_data["errors"].first["message"]
    ensure
      # Clean up
      ActionDispatch::Request.any_instance.unstub(:ip)
      Rails.cache.clear
    end
  end
end
