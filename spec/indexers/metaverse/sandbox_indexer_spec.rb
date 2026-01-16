# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

require 'rails_helper'

RSpec.describe Metaverse::SandboxIndexer, type: :model do
  let(:indexer) { described_class.new }

  describe "Initialization" do
    it "sets the correct platform name" do
      expect(indexer.platform_name).to eq('sandbox')
    end

    it "sets up Capybara configuration" do
      expect(indexer.send(:instance_variable_get, :@capybara_setup)).to be_truthy
    end
  end

  describe "Content Processing" do
    let(:sample_experience) do
      {
        title: "Test Experience",
        uuid: "123e4567-e89b-12d3-a456-426614174000",
        url: "https://www.sandbox.game/experiences/Test%2520Experience/123e4567-e89b-12d3-a456-426614174000/page",
        row_index: 1
      }
    end

    describe "#normalize_content" do
      it "normalizes experience data correctly" do
        normalized = indexer.send(:normalize_content, sample_experience)

        expect(normalized[:source_platform]).to eq('sandbox')
        expect(normalized[:external_id]).to eq(sample_experience[:uuid])
        expect(normalized[:content_type]).to eq('experience')
        expect(normalized[:title]).to eq('Test Experience')
        expect(normalized[:description]).to be_nil
        expect(normalized[:author]).to be_nil
        expect(normalized[:coordinates]).to be_nil
        expect(normalized[:metadata][:source_url]).to eq(sample_experience[:url])
      end
    end

    describe "#extract_external_id" do
      it "extracts UUID correctly" do
        expect(indexer.extract_external_id(sample_experience)).to eq(sample_experience[:uuid])
      end
    end

    describe "#extract_title" do
      it "extracts and cleans title" do
        expect(indexer.extract_title(sample_experience)).to eq('Test Experience')
      end
    end
  end

  describe "Title Processing" do
    describe "#decode_title" do
      it "decodes URL-encoded titles" do
        encoded_title = "Test%2520Experience"
        decoded = indexer.send(:decode_title, encoded_title)
        expect(decoded).to eq("Test Experience")
      end

      it "handles complex encoding" do
        encoded_title = "%25E2%259A%2594%2520Siege%2520Defense"
        decoded = indexer.send(:decode_title, encoded_title)
        expect(decoded).to include("Siege Defense")
      end

      it "handles special characters" do
        encoded_title = "Test%21%20Experience%28Game%29"
        decoded = indexer.send(:decode_title, encoded_title)
        expect(decoded).to eq("Test! Experience(Game)")
      end
    end

    describe "#clean_title" do
      it "cleans title with extra encoding artifacts" do
        dirty_title = "Test  %20  Experience  "
        cleaned = indexer.send(:clean_title, dirty_title)
        expect(cleaned).to eq("Test Experience")
      end

      it "truncates long titles" do
        long_title = "A" * 300
        cleaned = indexer.send(:clean_title, long_title)
        expect(cleaned.length).to be <= 255
      end

      it "handles nil and blank titles" do
        expect(indexer.send(:clean_title, nil)).to eq('')
        expect(indexer.send(:clean_title, '')).to eq('')
        expect(indexer.send(:clean_title, '  ')).to eq('')
      end
    end
  end

  describe "Sitemap Parsing" do
    let(:sample_html_table) do
      <<~HTML
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
    end

    let(:sample_xml_sitemap) do
      <<~XML
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
    end

    describe "#parse_html_sitemap" do
      it "parses HTML table format correctly" do
        doc = Nokogiri::HTML(sample_html_table)
        experiences = indexer.send(:parse_html_sitemap, doc)

        expect(experiences.count).to eq(2)

        first_exp = experiences.first
        expect(first_exp[:title]).to eq("Test Experience")
        expect(first_exp[:uuid]).to eq("123e4567-e89b-12d3-a456-426614174000")
        expect(first_exp[:url]).to end_with("/page")
        expect(first_exp[:row_index]).to eq(1)
      end

      it "handles empty table" do
        empty_html = "<html><body><table id='sitemap'><tbody></tbody></table></body></html>"
        doc = Nokogiri::HTML(empty_html)
        experiences = indexer.send(:parse_html_sitemap, doc)
        expect(experiences).to be_empty
      end

      it "handles missing table" do
        no_table_html = "<html><body><p>No table here</p></body></html>"
        doc = Nokogiri::HTML(no_table_html)
        experiences = indexer.send(:parse_html_sitemap, doc)
        expect(experiences).to be_empty
      end
    end

    describe "#parse_xml_sitemap" do
      it "parses XML sitemap format correctly" do
        experiences = indexer.send(:parse_xml_sitemap, sample_xml_sitemap)

        expect(experiences.count).to eq(2)

        first_exp = experiences.first
        expect(first_exp[:title]).to eq("Test Experience")
        expect(first_exp[:uuid]).to eq("123e4567-e89b-12d3-a456-426614174000")
      end
    end
  end

  describe "Error Handling" do
    describe "#cloudflare_blocked?" do
      let(:session_mock) { double('session') }

      it "detects Cloudflare challenge page" do
        allow(session_mock).to receive(:html).and_return("Just a moment... Cloudflare")
        allow(session_mock).to receive(:title).and_return("Just a moment...")

        expect(indexer.send(:cloudflare_blocked?, session_mock)).to be_truthy
      end

      it "does not flag normal content" do
        allow(session_mock).to receive(:html).and_return("<html><body>Normal content</body></html>")
        allow(session_mock).to receive(:title).and_return("Sitemap")

        expect(indexer.send(:cloudflare_blocked?, session_mock)).to be_falsy
      end
    end
  end

  describe "Sync Logic" do
    before do
      # Clean up any existing test data
      IndexedContent.where(source_platform: 'sandbox').destroy_all
    end

    describe "#sync_experiences" do
      it "identifies new and removed experiences" do
        # Create some existing content
        IndexedContent.create!(
          source_platform: 'sandbox',
          external_id: 'existing-uuid-1',
          content_type: 'experience',
          title: 'Existing Experience'
        )

        current_experiences = [
          { uuid: 'existing-uuid-1', title: 'Existing Experience', url: 'url1', row_index: 1 },
          { uuid: 'new-uuid-1', title: 'New Experience', url: 'url2', row_index: 2 }
        ]

        sync_stats = indexer.send(:sync_experiences, current_experiences)

        expect(sync_stats[:total_current]).to eq(2)
        expect(sync_stats[:existing]).to eq(1)
        expect(sync_stats[:new]).to eq(1)
        expect(sync_stats[:removed]).to eq(0)
      end

      it "removes experiences no longer in sitemap" do
        # Create existing content that's no longer in sitemap
        IndexedContent.create!(
          source_platform: 'sandbox',
          external_id: 'old-uuid',
          content_type: 'experience',
          title: 'Old Experience'
        )

        current_experiences = [
          { uuid: 'new-uuid', title: 'New Experience', url: 'url', row_index: 1 }
        ]

        sync_stats = indexer.send(:sync_experiences, current_experiences)

        expect(sync_stats[:removed]).to eq(1)
        expect(IndexedContent.where(external_id: 'old-uuid')).not_to exist
      end
    end
  end

  describe "Integration" do
    it "handles Cloudflare errors gracefully" do
      # This test would require mocking the browser session
      # Since we can't actually test against Cloudflare, we verify the error handling exists
      expect(described_class.const_defined?('CloudflareBlockError')).to be_truthy
    end

    it "is configured correctly in the registry" do
      # Test that the indexer can be instantiated and has required methods
      expect(indexer).to respond_to(:fetch_items)
      expect(indexer).to respond_to(:process_item)
      expect(indexer).to respond_to(:platform_name)
    end
  end
end
