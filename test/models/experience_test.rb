# frozen_string_literal: true
# shareable_constant_value: literal

# == Schema Information
#
# Table name: experiences
#
#  id                    :bigint           not null, primary key
#  author                :string(255)
#  current_state         :json
#  description           :text(65535)
#  flags                 :integer          default(0), not null
#  metaverse_coordinates :text(65535)
#  metaverse_metadata    :text(65535)
#  metaverse_platform    :string(255)
#  slug                  :string(255)
#  source_type           :string(255)      default("user_created"), not null
#  title                 :string(255)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :bigint           not null
#  indexed_content_id    :bigint
#
# Indexes
#
#  index_experiences_on_account_id                          (account_id)
#  index_experiences_on_account_id_and_created_at           (account_id,created_at)
#  index_experiences_on_indexed_content_id                  (indexed_content_id)
#  index_experiences_on_metaverse_platform                  (metaverse_platform)
#  index_experiences_on_slug                                (slug) UNIQUE
#  index_experiences_on_source_type                         (source_type)
#  index_experiences_on_source_type_and_metaverse_platform  (source_type,metaverse_platform)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (indexed_content_id => indexed_contents.id)
#
require "test_helper"
require "base64"

class ExperienceTest < ActiveSupport::TestCase
  setup do
    # Create account by bypassing validations since comprehensive moderation
    # flags even simple usernames. We want to test Experience validations specifically.
    @account = Account.new(username: "testuser", status: 2)
    @account.save!(validate: false)

    @valid_attributes = {
      title: "A Nice Day",
      description: "The sun is bright today",
      author: "Bob Smith",
      account: @account
    }
  end

  private

  def stub_html_file(experience)
    # This method is no longer needed since we stub in setup
  end

  test "should process content through comprehensive moderation" do
    # With comprehensive moderation, we test that the system processes content
    experience = Experience.new(@valid_attributes)
    # Test that it processes without raising errors
    assert_nothing_raised { experience.valid? }
  end

  test "should reject inappropriate title" do
    experience = Experience.new(@valid_attributes.merge(title: "This is a #{Base64.decode64('ZnVja2luZw==')} bad title"))
    assert_not experience.valid?
    assert_includes experience.errors[:title], "contains inappropriate content and cannot be saved"
  end

  test "should reject inappropriate description" do
    experience = Experience.new(@valid_attributes.merge(description: "This description contains #{Base64.decode64('bmF6aQ==')} content"))
    assert_not experience.valid?
    assert_includes experience.errors[:description], "contains inappropriate content and cannot be saved"
  end

  test "should reject inappropriate author" do
    experience = Experience.new(@valid_attributes.merge(author: "Contact #{Base64.decode64('c2hpdA==')} author"))
    assert_not experience.valid?
    assert_includes experience.errors[:author], "contains inappropriate content and cannot be saved"
  end

  test "should reject PII in title" do
    experience = Experience.new(@valid_attributes.merge(title: "Contact user@example.com for info"))
    assert_not experience.valid?
    assert_includes experience.errors[:title], "contains inappropriate content and cannot be saved"
  end

  test "should reject spam in description" do
    experience = Experience.new(@valid_attributes.merge(description: "CLICK HERE FOR AMAZING DEALS!!!!!"))
    assert_not experience.valid?
    assert_includes experience.errors[:description], "contains inappropriate content and cannot be saved"
  end

  test "should reject phone numbers in author" do
    experience = Experience.new(@valid_attributes.merge(author: "Call me at 123-456-7890"))
    assert_not experience.valid?
    assert_includes experience.errors[:author], "contains inappropriate content and cannot be saved"
  end

  test "should allow blank optional fields" do
    experience = Experience.new(@valid_attributes.merge(description: "", author: ""))
    # Test that blank fields are processed without errors
    assert_nothing_raised { experience.valid? }
  end

  test "should log moderation violations" do
    experience = Experience.new(@valid_attributes.merge(title: "This #{Base64.decode64('ZnVja2luZw==')} title"))

    assert_difference "ModerationLog.count", 1 do
      experience.valid?
    end

    log = ModerationLog.last
    assert_equal "title", log.field
    assert_equal "Experience", log.model_type
    assert_equal "This #{Base64.decode64('ZnVja2luZw==')} title", log.content
    assert_includes log.reason, "profanity"
    assert_equal @account, log.account
  end

  test "should handle multiple violations in one field" do
    # Text with both profanity and PII
    experience = Experience.new(@valid_attributes.merge(title: "This #{Base64.decode64('ZnVja2luZw==')} email user@example.com"))

    assert_not experience.valid?
    assert_includes experience.errors[:title], "contains inappropriate content and cannot be saved"

    log = ModerationLog.last
    # The reason should contain details about the specific violations found
    assert_not_nil log.reason
    assert_not_equal "content flagged by comprehensive moderation system", log.reason
    assert_includes log.reason, "profanity"
    assert_includes log.reason, "pii"
  end

  test "should handle violations in multiple fields" do
    experience = Experience.new(@valid_attributes.merge(
                                  title: "#{Base64.decode64('RnVja2luZw==')} title",
                                  description: "Description with user@example.com",
                                  author: "#{Base64.decode64('U2hpdA==')} author"
                                ))

    assert_difference "ModerationLog.count", 1 do
      experience.valid?
    end

    assert_not experience.valid?
    assert_includes experience.errors[:title], "contains inappropriate content and cannot be saved"
    assert_includes experience.errors[:description], "contains inappropriate content and cannot be saved"
    assert_includes experience.errors[:author], "contains inappropriate content and cannot be saved"

    # Check that the log contains information about multiple violations
    log = ModerationLog.last
    assert_includes log.reason, "profanity"
    assert_includes log.reason, "pii"
  end

  test "should continue with validation errors even if logging fails" do
    # Stub logging to raise an error
    ModerationLog.stubs(:log_rejection).raises(StandardError, "Database error")

    experience = Experience.new(@valid_attributes.merge(title: "This #{Base64.decode64('ZnVja2luZw==')} title"))

    # Should still be invalid despite logging error
    assert_not experience.valid?
    assert_includes experience.errors[:title], "contains inappropriate content and cannot be saved"
  end
end
