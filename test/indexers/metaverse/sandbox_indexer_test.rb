# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

require "test_helper"

module Metaverse
  class SandboxIndexerTest < ActiveSupport::TestCase
    def setup
      @indexer = SandboxIndexer.new
    end

    test "should detect cloudflare blocking via base class" do
      # Mock a session with cloudflare challenge
      session = OpenStruct.new(
        html: "<html><body>Cloudflare just a moment please...</body></html>",
        title: "Just a moment..."
      )

      assert @indexer.send(:is_blocked_by_cloudflare?, session)

      # Mock a normal session
      normal_session = OpenStruct.new(
        html: "<html><body>Normal content</body></html>",
        title: "Normal Title"
      )

      assert_not @indexer.send(:is_blocked_by_cloudflare?, normal_session)
    end

    test "should have correct platform name" do
      assert_equal "sandbox", @indexer.platform_name
    end

    test "should be properly configured as disabled" do
      assert_equal false, @indexer.config["enabled"]
    end

    test "should have correct sitemap URL" do
      assert_equal "https://www.sandbox.game/__sitemap__/experiences.xml", SandboxIndexer::SITEMAP_URL
    end

    test "should handle title decoding" do
      title_encoded = "Hello%2C%20World!"
      decoded = @indexer.send(:decode_title, title_encoded)
      assert_equal "Hello, World!", decoded
    end

    test "should clean titles properly" do
      # Test that clean_title handles already decoded content properly
      title_with_spaces = "Test Title ! (with symbols)"
      clean_title = @indexer.send(:clean_title, title_with_spaces)
      assert_equal "Test Title ! (with symbols)", clean_title

      # Test that it removes URL encoding artifacts (using real hex patterns)
      title_with_artifacts = "Test%20Title with %AB artifacts"
      cleaned_artifacts = @indexer.send(:clean_title, title_with_artifacts)
      assert_equal "Test Title with artifacts", cleaned_artifacts
    end

    test "should extract UUID from experience data" do
      data = { uuid: "12345678-1234-5678-9012-123456789012", title: "Test" }
      assert_equal "12345678-1234-5678-9012-123456789012", @indexer.send(:extract_external_id, data)
    end

    test "should normalize content correctly" do
      experience_data = {
        uuid: "12345678-1234-5678-9012-123456789012",
        title: "Test Experience",
        url: "https://www.sandbox.game/experiences/test/12345678-1234-5678-9012-123456789012/page",
        row_index: 1
      }

      normalized = @indexer.send(:normalize_content, experience_data)

      assert_equal "sandbox", normalized[:source_platform]
      assert_equal "12345678-1234-5678-9012-123456789012", normalized[:external_id]
      assert_equal "experience", normalized[:content_type]
      assert_equal "Test Experience", normalized[:title]
      assert_nil normalized[:description]
      assert_nil normalized[:author]
      assert_nil normalized[:coordinates]
      assert_includes normalized[:metadata], :source_url
      assert_includes normalized[:metadata], :indexed_at
    end

    # Skip this test if mock file doesn't exist
    if File.exist?(Rails.root.join("content-from-real-browser.html"))
      test "should parse real sitemap content" do
        mock_file = Rails.root.join("content-from-real-browser.html")
        html_content = File.read(mock_file)

        experiences = @indexer.send(:parse_sitemap_content, html_content)

        assert experiences.count > 1000, "Should find many experiences"
        assert experiences.all? { |exp| exp[:uuid] =~ /\A[0-9a-f-]{36}\z/ }, "All UUIDs should be valid"
        assert experiences.all? { |exp| exp[:title].present? }, "All experiences should have titles"
      end
    end
  end
end
