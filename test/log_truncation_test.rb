# frozen_string_literal: true

require "test_helper"
require "stringio"

class LogTruncationTest < ActiveSupport::TestCase
  test "truncates long messages to the configured length" do
    with_log_truncation(max_length: 32, omission: "[cut]") do
      formatter = Logger::Formatter.new
      payload = "a" * 128
      formatted = formatter.call("INFO", Time.utc(2024, 1, 1), "prog", payload)

      assert_includes formatted, "[cut]"

      body = extract_body(formatted, "prog")
      assert_not_nil body

      assert_equal 32, body.length
      assert body.end_with?("[cut]")
    end
  end

  test "truncation applies to ActiveSupport simple formatter" do
    skip "ActiveSupport::Logger::SimpleFormatter not present" unless defined?(ActiveSupport::Logger::SimpleFormatter)

    with_log_truncation(max_length: 40, omission: "…") do
      formatter = ActiveSupport::Logger::SimpleFormatter.new
      payload = "SELECT * FROM users WHERE bio = '#{'x' * 200}'"
      formatted = formatter.call("INFO", Time.utc(2024, 1, 1), "ActiveRecord", payload)

      body = extract_body(formatted, "ActiveRecord")
      assert_not_nil body

      assert_operator body.length, :<=, 40
      assert body.end_with?("…")
    end
  end

  test "leaves short messages untouched" do
    with_log_truncation(max_length: 32, omission: "[cut]") do
      formatter = Logger::Formatter.new
      payload = "short message"
      formatted = formatter.call("INFO", Time.utc(2024, 1, 1), "prog", payload)

      body = extract_body(formatted, "prog")
      assert_not_nil body

      assert_equal payload, body
    end
  end

  test "custom tagged formatter truncates messages" do
    skip "CustomTaggedFormatter not available" unless defined?(CustomTaggedFormatter)

    with_log_truncation(max_length: 48, omission: "[snip]") do
      base_logger = ActiveSupport::Logger.new(StringIO.new)
      formatter = ActiveSupport::TaggedLogging.new(base_logger).formatter
      formatter.extend(CustomTaggedFormatter)

      payload = "SQL #{'x' * 256}"
      formatted = formatter.call("INFO", Time.utc(2024, 1, 1), "ActiveRecord", payload)

      body = extract_body(formatted, "ActiveRecord")
      assert_not_nil body

      assert body.end_with?("[snip]")
      assert_operator body.length, :<=, 48
    end
  end

  private

  def with_log_truncation(max_length:, omission:)
    original_length = LogFormatting.max_message_length
    original_omission = LogFormatting.omission

    LogFormatting.configure(max_length: max_length, omission: omission)
    yield
  ensure
    LogFormatting.configure(max_length: original_length, omission: original_omission)
  end

  def extract_body(formatted, progname)
    return formatted.split(" -- #{progname}: ", 2).last&.delete_suffix("\n") if formatted.include?(" -- #{progname}: ")

    return formatted.split(" #{progname} -- ", 2).last&.delete_suffix("\n") if formatted.include?(" #{progname} -- ")

    if formatted.start_with?("[")
      body = formatted.split("] ", 4).last
      return body&.delete_suffix("\n")
    end

    formatted.delete_suffix("\n")
  end
end
