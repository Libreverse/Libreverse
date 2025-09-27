require "test_helper"

class ProxyControllerTest < ActionDispatch::IntegrationTest
  test "should proxy umami script in production" do
    # Mock Rails environment to be production
    Rails.env.stubs(:production?).returns(true)

    # Mock the HTTParty request to Umami
    mock_response = mock
    mock_response.stubs(:body).returns("console.log('umami script');")
    mock_response.stubs(:code).returns(200)

    HTTParty.stubs(:get).returns(mock_response)

    get "/umami/script.js"

    assert_response :success
    assert_equal "application/javascript; charset=utf-8", response.headers["Content-Type"]
    assert_includes response.headers["Cache-Control"], "max-age=86400"
    assert_includes response.headers["Cache-Control"], "public"
    assert_equal "nosniff", response.headers["X-Content-Type-Options"]
    assert_includes response.body, "umami script"
  end

  test "should return 404 in development" do
    Rails.env.stubs(:production?).returns(false)

    get "/umami/script.js"
    assert_response :not_found
  end

  test "should return 404 in test environment" do
    # In test environment, production? returns false by default
    get "/umami/script.js"
    assert_response :not_found
  end

  test "should handle network errors gracefully" do
    Rails.env.stubs(:production?).returns(true)

    # Mock network error
    HTTParty.stubs(:get).raises(StandardError.new("Network error"))

    get "/umami/script.js"
    assert_response :not_found
  end

  test "should handle timeout errors gracefully" do
    Rails.env.stubs(:production?).returns(true)

    # Mock timeout error
    HTTParty.stubs(:get).raises(Timeout::Error.new("Timeout"))

    get "/umami/script.js"
    assert_response :not_found
  end

  test "should set proper security headers" do
    Rails.env.stubs(:production?).returns(true)

    mock_response = mock
    mock_response.stubs(:body).returns("console.log('test');")
    mock_response.stubs(:code).returns(200)

    HTTParty.stubs(:get).returns(mock_response)

    get "/umami/script.js"

    assert_response :success
    assert_equal "nosniff", response.headers["X-Content-Type-Options"]
  end
end
