# typed: true
# frozen_string_literal: true
# shareable_constant_value: literal

require "test_helper"

module Metaverse
  class SandboxIndexerTest < ActiveSupport::TestCase
    def setup
      @indexer = SandboxIndexer.new
      @sample_experience = {
        title: "Test Experience",
        uuid: "123e4567-e89b-12d3-a456-426614174000",
        url: "https://www.sandbox.game/experiences/Test%2520Experience/123e4567-e89b-12d3-a456-426614174000/page",
        row_index: 1
      }
    end

    test "platform name is sandbox" do
      assert_equal "sandbox", @indexer.platform_name
    end

    test "cloudflare challenge is detected" do
      session = OpenStruct.new(html: "Just a moment... Cloudflare", title: "Just a moment...")
      assert @indexer.send(:is_blocked_by_cloudflare?, session)
    end

    test "normal content is not treated as cloudflare challenge" do
      session = OpenStruct.new(html: "<html><body>Normal content</body></html>", title: "Sitemap")
      assert_not @indexer.send(:is_blocked_by_cloudflare?, session)
    end

    test "normalize_content maps expected fields" do
      normalized = @indexer.send(:normalize_content, @sample_experience)

      assert_equal "sandbox", normalized[:source_platform]
      assert_equal @sample_experience[:uuid], normalized[:external_id]
      assert_equal "experience", normalized[:content_type]
      assert_equal "Test Experience", normalized[:title]
      assert_nil normalized[:description]
      assert_nil normalized[:author]
      assert_nil normalized[:coordinates]
      assert_equal @sample_experience[:url], normalized.dig(:metadata, :source_url)
    end

    test "extract_external_id returns UUID" do
      assert_equal @sample_experience[:uuid], @indexer.send(:extract_external_id, @sample_experience)
    end

    test "extract_title decodes and cleans title" do
      assert_equal "Test Experience", @indexer.send(:extract_title, @sample_experience)
    end

    test "decode_title handles nested encoding" do
      assert_equal "Test Experience", @indexer.send(:decode_title, "Test%2520Experience")
      assert_includes @indexer.send(:decode_title, "%25E2%259A%2594%2520Siege%2520Defense"), "Siege Defense"
      assert_equal "Test! Experience(Game)", @indexer.send(:decode_title, "Test%21%20Experience%28Game%29")
    end

    test "clean_title strips artifacts and truncates" do
      assert_equal "Test Experience", @indexer.send(:clean_title, "Test  %20  Experience  ")
      assert_equal "", @indexer.send(:clean_title, nil)
      assert_equal "", @indexer.send(:clean_title, "")
      assert_equal "", @indexer.send(:clean_title, "  ")
      assert_operator @indexer.send(:clean_title, "A" * 300).length, :<=, 255
    end

    test "parse_html_sitemap parses table rows" do
      html = <<~HTML
        <html>
          <body>
            <table id="sitemap">
              <tbody>
                <tr>
                  <td>
                    <a href="https://www.sandbox.game/experiences/Test%2520Experience/123e4567-e89b-12d3-a456-426614174000/page">Test Experience</a>
                  </td>
                </tr>
                <tr>
                  <td>
                    <a href="https://www.sandbox.game/experiences/Another%2520Game/456e7890-e89b-12d3-a456-426614174000/page">Another Game</a>
                  </td>
                </tr>
              </tbody>
            </table>
          </body>
        </html>
      HTML

      experiences = @indexer.send(:parse_html_sitemap, Nokogiri::HTML(html))

      assert_equal 2, experiences.count
      assert_equal "Test Experience", experiences.first[:title]
      assert_equal "123e4567-e89b-12d3-a456-426614174000", experiences.first[:uuid]
      assert_match %r{/page\z}, experiences.first[:url]
      assert_equal 1, experiences.first[:row_index]
    end

    test "parse_html_sitemap handles empty or missing table" do
      empty = Nokogiri::HTML("<html><body><table id='sitemap'><tbody></tbody></table></body></html>")
      missing = Nokogiri::HTML("<html><body><p>No table here</p></body></html>")

      assert_empty @indexer.send(:parse_html_sitemap, empty)
      assert_empty @indexer.send(:parse_html_sitemap, missing)
    end

    test "parse_xml_sitemap parses urlset format" do
      xml = <<~XML
        <?xml version='1.0' encoding='UTF-8'?>
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
          <url>
            <loc>https://www.sandbox.game/experiences/Test%2520Experience/123e4567-e89b-12d3-a456-426614174000/page</loc>
          </url>
          <url>
            <loc>https://www.sandbox.game/experiences/Another%2520Game/456e7890-e89b-12d3-a456-426614174000/page</loc>
          </url>
        </urlset>
      XML

      experiences = @indexer.send(:parse_xml_sitemap, xml)

      assert_equal 2, experiences.count
      assert_equal "Test Experience", experiences.first[:title]
      assert_equal "123e4567-e89b-12d3-a456-426614174000", experiences.first[:uuid]
    end

    test "sync_experiences identifies existing new and removed" do
      IndexedContent.where(source_platform: "sandbox").destroy_all

      IndexedContent.create!(
        source_platform: "sandbox",
        external_id: "existing-uuid-1",
        content_type: "experience",
        title: "Existing Experience"
      )

      sync_stats = @indexer.send(:sync_experiences, [
        { uuid: "existing-uuid-1", title: "Existing Experience", url: "url1", row_index: 1 },
        { uuid: "new-uuid-1", title: "New Experience", url: "url2", row_index: 2 }
      ])

      assert_equal 2, sync_stats[:total_current]
      assert_equal 1, sync_stats[:existing]
      assert_equal 1, sync_stats[:new]
      assert_equal 0, sync_stats[:removed]
    end

    test "sync_experiences removes entries not present in sitemap" do
      IndexedContent.where(source_platform: "sandbox").destroy_all

      IndexedContent.create!(
        source_platform: "sandbox",
        external_id: "old-uuid",
        content_type: "experience",
        title: "Old Experience"
      )

      sync_stats = @indexer.send(:sync_experiences, [
        { uuid: "new-uuid", title: "New Experience", url: "url", row_index: 1 }
      ])

      assert_equal 1, sync_stats[:removed]
      assert_not IndexedContent.exists?(external_id: "old-uuid")
    end

    test "indexer class includes expected integration points" do
      assert Metaverse::SandboxIndexer.const_defined?("CloudflareBlockError")
      assert_respond_to @indexer, :fetch_items
      assert_respond_to @indexer, :process_item
      assert_respond_to @indexer, :platform_name
    end
  end
end
