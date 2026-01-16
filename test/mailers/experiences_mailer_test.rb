# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

require "test_helper"

class ExperiencesMailerTest < ActionMailer::TestCase
  test "should generate ZIP attachment using rubyzip for email" do
    experience_data = {
      title: "Test Experience",
      author: "Test Author",
      url: "https://example.com/test",
      content: "<p>This is test content</p>"
    }

    # Test the generate_experience_zip method directly
    mailer = ExperiencesMailer.new
    zip_content = mailer.send(:generate_experience_zip, experience_data)

    # Verify it's valid ZIP content (rubyzip format)
    assert zip_content.present?
    assert zip_content.start_with?("PK"), "ZIP content should start with ZIP signature"

    # Verify we can read it back with rubyzip
    zip_io = StringIO.new(zip_content)

    require "zip"
    files_found = []
    Zip::File.open_buffer(zip_io) do |zip_file|
      zip_file.each do |entry|
        files_found << entry.name
      end
    end

  # Verify expected files are present
  assert_includes files_found, "test_experience.html"
    assert_includes files_found, "README.txt"
    assert_includes files_found, "metadata.json"
  end

  test "should send offline experience email with ZIP attachment" do
    experience_data = {
      title: "Test Experience",
      author: "Test Author",
      url: "https://example.com/test",
      content: "<p>This is test content</p>"
    }

    email = ExperiencesMailer.offline_experience(
      "test@example.com",
      "Test User",
      experience_data
    )

    # Verify email properties
    assert_equal [ "test@example.com" ], email.to
    assert_includes email.subject, "Test Experience"

    # Verify ZIP attachment is present
    assert_equal 1, email.attachments.count
    attachment = email.attachments.first
    assert_includes attachment.filename, ".zip"
    assert_equal "application/zip", attachment.content_type

    # Verify attachment content is valid ZIP
    assert attachment.body.raw_source.start_with?("PK"), "Attachment should be valid ZIP"
  end
end
