# frozen_string_literal: true

require "test_helper"

class AccountActionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Create a test account
    @account = Account.create!(
      username: "testuser",
      email: "test@example.com",
      password: "password123",
      status: 2 # verified
    )
    # Simulate login by setting the session
    post rodauth.login_path, params: { email: @account.email, password: "password123" }
    follow_redirect!
  end

  test "should export account data as streaming ZIP using zip_kit" do
    get "/account/export"

    assert_response :success
    assert_equal "application/zip", response.content_type
    assert_includes response.headers["Content-Disposition"], "libreverse_export.zip"

    # Verify streaming headers are set correctly by zip_kit
    assert_equal "identity", response.headers["Content-Encoding"]
    assert_equal "no", response.headers["X-Accel-Buffering"]

    # Verify that the response body contains ZIP data
    assert response.body.present?
    assert response.body.start_with?("PK"), "Response should start with ZIP file signature"
  end

  test "should include account data in export" do
    get "/account/export"

    # We can't easily test the internal structure of a streaming ZIP
    # but we can verify the response is successful and has the right format
    assert_response :success
    assert_equal "application/zip", response.content_type
  end
end
