# frozen_string_literal: true

require "test_helper"

module Api
  class JsonControllerTest < ActionController::TestCase
    # Don't use fixtures for this test
    self.use_transactional_tests = true

    setup do
      # Start with a clean slate
      Experience.delete_all
      UserPreference.delete_all

      # Skip certain before_action methods that could cause issues
      @controller.stubs(:apply_rate_limit).returns(true)
      # Skip CSRF verification for tests (but we'll test it separately)
      @controller.stubs(:verify_csrf_for_state_changing_methods).returns(true)

      # Create two test experiences
      @experience1 = Experience.new(
        title: "Safe Experience One",
        description: "A safe description for the first experience",
        author: "Safe Author One",
        account: accounts(:one),
        approved: true
      )

      # Attach a basic HTML file for first experience
      html_content1 = "<html><body><h1>Safe Experience One</h1></body></html>"
      @experience1.html_file.attach(
        io: StringIO.new(html_content1),
        filename: "safe_experience_1.html",
        content_type: "text/html"
      )

      @experience1.save!

      @experience2 = Experience.new(
        title: "Safe Experience Two",
        description: "A safe description for the second experience",
        author: "Safe Author Two",
        account: accounts(:two),
        approved: true
      )

      # Attach a basic HTML file for second experience
      html_content2 = "<html><body><h1>Safe Experience Two</h1></body></html>"
      @experience2.html_file.attach(
        io: StringIO.new(html_content2),
        filename: "safe_experience_2.html",
        content_type: "text/html"
      )

      @experience2.save!

      # Create an unapproved experience for testing
      @unapproved_experience = Experience.new(
        title: "Unapproved Experience",
        description: "This experience needs approval",
        author: "Test Author",
        account: accounts(:one),
        approved: false
      )

      html_content3 = "<html><body><h1>Unapproved Experience</h1></body></html>"
      @unapproved_experience.html_file.attach(
        io: StringIO.new(html_content3),
        filename: "unapproved_experience.html",
        content_type: "text/html"
      )

      @unapproved_experience.save!

      # Set the JSON content type for all requests
      @request.env["CONTENT_TYPE"] = "application/json"
    end

    teardown do
      Experience.delete_all
      UserPreference.delete_all
    end

    test "should get all experiences via GET" do
      get :endpoint, params: { method: "experiences.all" }

      assert_response :success
      json_response = JSON.parse(response.body)

      assert json_response["result"].is_a?(Array)
      assert_equal 2, json_response["result"].length
    end

    test "should get all experiences via POST with JSON" do
      post :endpoint, params: { method: "experiences.all" }, as: :json

      assert_response :success
      json_response = JSON.parse(response.body)

      assert json_response["result"].is_a?(Array)
      assert_equal 2, json_response["result"].length
    end

    test "should get single experience" do
      get :endpoint, params: { method: "experiences.get", id: @experience1.id }

      assert_response :success
      json_response = JSON.parse(response.body)

      assert_equal "Safe Experience One", json_response["result"]["title"]
      assert_equal @experience1.id, json_response["result"]["id"]
    end

    test "should get approved experiences only" do
      get :endpoint, params: { method: "experiences.approved" }

      assert_response :success
      json_response = JSON.parse(response.body)

      # Should only return approved experiences
      assert_equal 2, json_response["result"].length
    end

    test "should search experiences with public query" do
      get :endpoint, params: {
        method: "search.public_query",
        query: "Safe",
        limit: 10
      }

      assert_response :success
      json_response = JSON.parse(response.body)

      assert_equal 2, json_response["result"].length
    end

        test "should create experience when authenticated" do
      # Simulate authentication
      @controller.stubs(:current_account).returns(accounts(:one))

      # Temporarily disable moderation for this test
      Experience.any_instance.stubs(:content_moderation).returns(nil)

      post :endpoint, params: {
        method: "experiences.create",
        title: "New Test Experience",
        description: "Test description",
        html_content: "<html><body>Test content</body></html>",
        # Don't specify author, let it default to current_account.username
      }

      assert_response :success
      json_response = JSON.parse(response.body)

      assert_equal "New Test Experience", json_response["result"]["title"]
        end

    test "should handle preferences.set" do
      # Simulate authentication
      @controller.stubs(:current_account).returns(accounts(:one))

      post :endpoint, params: {
        method: "preferences.set",
        key: "dashboard-tutorial",
        value: "true"
      }

      assert_response :success
      json_response = JSON.parse(response.body)

      assert_equal true, json_response["result"]["success"]
    end

    test "should handle preferences.get" do
      # Simulate authentication and set a preference first
      @controller.stubs(:current_account).returns(accounts(:one))
      UserPreference.set(accounts(:one).id, "dashboard-tutorial", "t")

      get :endpoint, params: {
        method: "preferences.get",
        key: "dashboard-tutorial"
      }

      assert_response :success
      json_response = JSON.parse(response.body)

      assert_equal "t", json_response["result"]["value"]
    end

    test "should handle preferences.is_dismissed" do
      # Simulate authentication and set a dismissed preference
      @controller.stubs(:current_account).returns(accounts(:one))
      UserPreference.dismiss(accounts(:one).id, "welcome-message")

      get :endpoint, params: {
        method: "preferences.is_dismissed",
        key: "welcome-message"
      }

      assert_response :success
      json_response = JSON.parse(response.body)

      assert_equal true, json_response["result"]["dismissed"]
    end

    test "should get account info when authenticated" do
      # Simulate authentication
      @controller.stubs(:current_account).returns(accounts(:one))

      get :endpoint, params: { method: "account.get_info" }

      assert_response :success
      json_response = JSON.parse(response.body)

      assert_equal accounts(:one).username, json_response["result"]["username"]
    end

    test "should require authentication for protected methods" do
      # Don't authenticate
      @controller.stubs(:current_account).returns(nil)

      post :endpoint, params: {
        method: "experiences.create",
        title: "Test"
      }, as: :json

      assert_response :forbidden
      json_response = JSON.parse(response.body)

      assert_equal "Method not allowed", json_response["error"]
    end

    test "should reject invalid preference keys" do
      # Simulate authentication
      @controller.stubs(:current_account).returns(accounts(:one))

      get :endpoint, params: {
        method: "preferences.get",
        key: "invalid-key"
      }

      assert_response :internal_server_error
      json_response = JSON.parse(response.body)

      assert_equal "Internal server error", json_response["error"]
    end

    test "should reject invalid method names" do
      get :endpoint, params: { method: "nonexistent.method" }

      assert_response :forbidden
      json_response = JSON.parse(response.body)

      assert_equal "Method not allowed", json_response["error"]
    end

    test "should reject empty method name" do
      get :endpoint, params: { method: "" }

      assert_response :bad_request
      json_response = JSON.parse(response.body)

      assert_equal "Invalid method name", json_response["error"]
    end

    test "should handle POST with JSON body parameters" do
      post :endpoint, params: { method: "search.public_query" }

      # This should work even without parameters
      assert_response :success
    end

    test "should validate content type for POST without method in URL" do
      # Don't stub CSRF for this test since we're not testing CSRF functionality
      @controller.unstub(:verify_csrf_for_state_changing_methods)
      @request.env["CONTENT_TYPE"] = "text/plain"

      post :endpoint, params: { some: "data" }

      assert_response :unsupported_media_type
      json_response = JSON.parse(response.body)

      assert_equal "Unsupported content type. Use application/json", json_response["error"]
    end

    test "should reject malformed method names" do
      get :endpoint, params: { method: "invalid..method" }

      assert_response :bad_request
      json_response = JSON.parse(response.body)

      assert_equal "Invalid method name", json_response["error"]
    end

    test "should require CSRF token for state-changing methods" do
      # Remove the CSRF stub to test actual CSRF protection
      @controller.unstub(:verify_csrf_for_state_changing_methods)
      @controller.stubs(:current_account).returns(accounts(:one))

      # Attempt to create experience without CSRF token
      post :endpoint, params: {
        method: "experiences.create",
        title: "Test Experience",
        description: "Test description",
        html_content: "<html><body>Test content</body></html>"
      }

      assert_response :forbidden
      json_response = JSON.parse(response.body)

      assert_equal "CSRF token missing or invalid", json_response["error"]
    end

    test "should allow state-changing methods with valid CSRF token" do
      # Remove the CSRF stub to test actual CSRF protection
      @controller.unstub(:verify_csrf_for_state_changing_methods)
      @controller.stubs(:current_account).returns(accounts(:one))

      # Temporarily disable moderation for this test
      Experience.any_instance.stubs(:content_moderation).returns(nil)

      # Get a valid CSRF token
      csrf_token = @controller.send(:form_authenticity_token)

      # Attempt to create experience with CSRF token
      @request.env["HTTP_X_CSRF_TOKEN"] = csrf_token

      post :endpoint, params: {
        method: "experiences.create",
        title: "Test Experience",
        description: "Test description",
        html_content: "<html><body>Test content</body></html>"
        # Don't specify author, let it default to current_account.username
      }

      assert_response :success
      json_response = JSON.parse(response.body)

      assert_equal "Test Experience", json_response["result"]["title"]
    end

    test "should allow GET requests without CSRF token" do
      # Remove the CSRF stub to test that GET requests work without CSRF
      @controller.unstub(:verify_csrf_for_state_changing_methods)

      get :endpoint, params: { method: "experiences.all" }

      assert_response :success
      json_response = JSON.parse(response.body)

      assert json_response["result"].is_a?(Array)
    end
  end
end
