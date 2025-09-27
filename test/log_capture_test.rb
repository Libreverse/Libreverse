require "test_helper"

class LogCaptureTest < ActiveSupport::TestCase
  # Don't use fixtures for this test
  no_fixtures

  test "passing test should not show logs" do
    Rails.logger.info "This log should not be shown"

    assert true
  end
end
