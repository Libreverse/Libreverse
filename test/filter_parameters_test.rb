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
    filters = Rails.application.config.filter_parameters
    filters = [ filters ] unless filters.is_a?(Array)

    regex_filters = filters.select { |f| f.is_a?(Regexp) }
    value_filters = filters.reject { |f| f.is_a?(Regexp) }.map(&:to_s)

    REQUIRED_FILTERED_FIELDS.each do |field|
      if regex_filters.any?
        assert regex_filters.any? { |re| field.to_s =~ re }, "Missing filter for parameter: #{field} (regex mode)"
      else
        assert_includes value_filters, field.to_s, "Missing filter for parameter: #{field} (value mode)"
      end
    end
  end
end
