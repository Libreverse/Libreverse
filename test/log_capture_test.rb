# frozen_string_literal: true

require "test_helper"

class LogCaptureTest < ActiveSupport::TestCase
  # Don't use fixtures for this test
  no_fixtures

  test "passing test should not show logs" do
    Rails.logger.info "This log should not be shown"
    Rails.logger.debug "Neither should this debug log"
    Rails.logger.warn "Or this warning"

    assert true
  end

  test "failing test should show captured logs" do
    Rails.logger.info "This log SHOULD be shown because test fails"
    Rails.logger.debug "This debug log should also be shown"
    Rails.logger.warn "And this warning too"

    # Uncomment the line below to make this test fail and see the logs
    # assert false, "This test intentionally fails to demonstrate log capture"

    # For now, make it pass so we can test the passing case
    assert true
  end
end
