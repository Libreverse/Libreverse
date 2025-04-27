# frozen_string_literal: true

require "test_helper"

class FilterParametersTest < ActiveSupport::TestCase
  # List of all sensitive/PII fields that must be filtered from logs
  REQUIRED_FILTERED_FIELDS = %i[
    passw secret token _key crypt salt certificate otp ssn
    name username email address phone birth gender national
    card account iban bank tax income
    health medical insurance
    csrf xsrf session cookie auth
    social verification answer key secret_question
  ].freeze

  test "all required PII fields are filtered from logs" do
    filtered = Rails.application.config.filter_parameters.map(&:to_s)
    REQUIRED_FILTERED_FIELDS.each do |field|
      assert_includes filtered, field.to_s, "Missing filter for parameter: #{field}"
    end
  end
end
