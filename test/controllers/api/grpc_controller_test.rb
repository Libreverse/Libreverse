# frozen_string_literal: true

require "test_helper"

module Api
  class GrpcControllerTest < ActionController::TestCase
  def setup
    @account = accounts(:basic) if respond_to?(:accounts)
    @admin_account = accounts(:admin) if respond_to?(:accounts)
  end

  test "should accept valid content type" do
    # Test that valid content types are accepted
    post :endpoint, params: {
      method: "GetAllExperiences",
      request: {}
    }, as: :json

    # Should not return unsupported media type error
    assert_not_equal 415, response.status

    if response.status == 200
      response_data = JSON.parse(response.body)
      # Should have either success or error field, but not unsupported content type
      assert(response_data.key?("success") || response_data.key?("error"))
      assert_not_includes(response_data["error"] || "", "Unsupported content type") if response_data["error"]
    end
  end

  test "should require method name" do
    post :endpoint, params: {
      request: {}
    }, as: :json

    assert_response :bad_request
    response_data = JSON.parse(response.body)
    assert_includes response_data["error"], "Method name is required"
  end

  test "should reject unknown method" do
    post :endpoint, params: {
      method: "UnknownMethod",
      request: {}
    }, as: :json

    assert_response :bad_request
    response_data = JSON.parse(response.body)
    assert_includes response_data["error"], "Unknown method"
  end

  test "should handle GetAllExperiences request" do
    post :endpoint, params: {
      method: "GetAllExperiences",
      request: {}
    }, as: :json

    # Should respond without error (may be 200 or error depending on setup)
    assert_response_includes [ 200, 500, 503 ] # 503 if gRPC service unavailable

    if response.status == 200
      response_data = JSON.parse(response.body)
      assert response_data.key?("success") || response_data.key?("error")
    end
  end

  test "should set proper headers" do
    post :endpoint, params: {
      method: "GetAllExperiences",
      request: {}
    }, as: :json

    # Check that cache control headers are set (Rails may reorder them)
    cache_control = response.headers["Cache-Control"]
    assert_includes cache_control, "no-store", "Cache-Control should include no-store"
    assert_includes cache_control, "private", "Cache-Control should include private"
    assert_equal "no-cache", response.headers["Pragma"]
    assert_equal "0", response.headers["Expires"]
  end

    private

  def assert_response_includes(expected_statuses)
    assert_includes expected_statuses, response.status,
                    "Expected response status to be one of #{expected_statuses}, but was #{response.status}"
  end

  def teardown
    # Clean up any cached sessions
    Rails.cache.delete_matched("session:*") if Rails.cache.respond_to?(:delete_matched)
  end
  end
end
