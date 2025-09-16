# frozen_string_literal: true

require 'test_helper'

class CachePreloadJobTest < ActiveJob::TestCase
  test 'warms URLs from sitemap' do
    sitemap_xml = <<~XML
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <url><loc>https://example.com/</loc></url>
        <url><loc>https://example.com/about</loc></url>
      </urlset>
    XML

    # Stub base_url for the job instance(s)
    CachePreloadJob.any_instance.stubs(:base_url).returns('https://example.com')

    # Stub robots to have no sitemap, so it falls back to /sitemap.xml
    robots_resp = stub(code: 200, body: "")
    HTTParty.stubs(:get).with('https://example.com/robots.txt', kind_of(Hash)).returns(robots_resp)

    # Stub sitemap.xml
    sm_resp = stub(code: 200, body: sitemap_xml, headers: {})
    HTTParty.stubs(:get).with('https://example.com/sitemap.xml', kind_of(Hash)).returns(sm_resp)

    # Expect GETs to each page URL
    page_resp = stub(code: 200, body: '')
    HTTParty.expects(:get).with('https://example.com/', kind_of(Hash)).returns(page_resp)
    HTTParty.expects(:get).with('https://example.com/about', kind_of(Hash)).returns(page_resp)

    # Run
    assert_nothing_raised do
      CachePreloadJob.perform_now(max_urls: 100, rate_limit_ms: 0)
    end
  end
end
