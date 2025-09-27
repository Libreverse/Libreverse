require "test_helper"
require "nokogiri"

class SitemapControllerTest < ActionController::TestCase
  setup do
    # Clear cache to ensure clean test state
    Rails.cache.clear

    # Disable content moderation for these tests
    Experience.any_instance.stubs(:content_moderation).returns(nil)

    # Delete all ExperienceVector and Experience records
    ExperienceVector.delete_all
    Experience.delete_all

    # Create test experiences with approved status using safe content
    @approved_experience1 = Experience.create!(
      title: "A Nice Day Outside",
      description: "The sun is bright and the weather is pleasant",
      author: "Alice Johnson",
      account: accounts(:one),
      approved: true,
      updated_at: 2.days.ago
    )

    @approved_experience2 = Experience.create!(
      title: "Learning Something New",
      description: "Today I discovered something interesting about nature",
      author: "Bob Smith",
      account: accounts(:two),
      approved: true,
      updated_at: 1.day.ago
    )

    @unapproved_experience = Experience.create!(
      title: "Pending Review",
      description: "This experience is waiting for moderation",
      author: "Charlie Brown",
      account: accounts(:one),
      approved: false
    )
  end

  teardown do
    ExperienceVector.delete_all
    Experience.delete_all
    Rails.cache.clear
    # Unstub content moderation
    Experience.any_instance.unstub(:content_moderation)
  end

  test "should generate sitemap.xml with correct XML structure" do
    get :show, format: :xml

    assert_response :success
    assert_equal "application/xml; charset=utf-8", response.content_type

    # Parse the XML to validate structure
    xml_doc = Nokogiri::XML(response.body)
    assert xml_doc.errors.empty?, "XML should be valid"

    # Check root element (urlset has default namespace)
    urlset = xml_doc.at_xpath("//xmlns:urlset", "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9")
    assert_not_nil urlset, "urlset element not found in XML"
    assert_equal "http://www.sitemaps.org/schemas/sitemap/0.9", urlset.namespace.href
  end

  test "should include main site pages in sitemap" do
    get :show, format: :xml

    assert_response :success

    xml_doc = Nokogiri::XML(response.body)
    urls = xml_doc.xpath("//xmlns:url/xmlns:loc", "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9").map(&:text)

    # Check for main pages (SitemapGenerator creates URLs without trailing slash for root)
    assert_includes urls, request.base_url.to_s
    assert_includes urls, "#{request.base_url}/experiences"
    assert_includes urls, "#{request.base_url}/search"
    assert_includes urls, "#{request.base_url}/terms"
    assert_includes urls, "#{request.base_url}/privacy"
  end

  test "should include only approved experiences in sitemap" do
    get :show, format: :xml

    assert_response :success

    xml_doc = Nokogiri::XML(response.body)
    urls = xml_doc.xpath("//xmlns:url/xmlns:loc", "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9").map(&:text)

    # Check approved experiences are included
    assert_includes urls, "#{request.base_url}/experiences/#{@approved_experience1.id}/display"
    assert_includes urls, "#{request.base_url}/experiences/#{@approved_experience2.id}/display"

    # Check unapproved experience is not included
    assert_not_includes urls, "#{request.base_url}/experiences/#{@unapproved_experience.id}/display"
  end

  test "should include proper metadata for experience URLs" do
    get :show, format: :xml

    assert_response :success

    xml_doc = Nokogiri::XML(response.body)

    # Find the URL for our approved experience
    experience_url = xml_doc.xpath("//xmlns:url[xmlns:loc='#{request.base_url}/experiences/#{@approved_experience1.id}/display']", "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9")
    assert_not_nil experience_url

    # Check lastmod exists and is properly formatted
    lastmod = experience_url.at_xpath("xmlns:lastmod", "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9")
    assert_not_nil lastmod
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, lastmod.text)

    # Check changefreq
    changefreq = experience_url.at_xpath("xmlns:changefreq", "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9")
    assert_not_nil changefreq
    assert_equal "weekly", changefreq.text

    # Check priority
    priority = experience_url.at_xpath("xmlns:priority", "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9")
    assert_not_nil priority
    assert_equal "0.6", priority.text
  end

  test "should use canonical host when configured" do
    # Clear cache to ensure fresh generation
    Rails.cache.clear

    # Set a canonical host
    InstanceSetting.set("canonical_host", "https://example.com")

    get :show, format: :xml

    assert_response :success

    xml_doc = Nokogiri::XML(response.body)
    urls = xml_doc.xpath("//xmlns:url/xmlns:loc", "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9").map(&:text)

    # All URLs should use the canonical host
    urls.each do |url|
      assert_match(%r{^https://example\.com(?:/|$)}, url)
    end

    # Clean up
    InstanceSetting.where(key: "canonical_host").delete_all
  end

  test "should fall back to request base_url when no canonical host" do
    # Ensure no canonical host is set
    InstanceSetting.where(key: "canonical_host").delete_all

    get :show, format: :xml

    assert_response :success

    xml_doc = Nokogiri::XML(response.body)
    urls = xml_doc.xpath("//xmlns:url/xmlns:loc", "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9").map(&:text)

    # All URLs should use request base_url
    urls.each do |url|
      assert_match(/^#{Regexp.escape(request.base_url)}/, url)
    end
  end

  test "should set proper cache headers" do
    # Skip this test in development environment where cache headers are disabled
    skip "Cache headers disabled in development" if Rails.env.development?

    get :show, format: :xml

    assert_response :success
    assert_equal "max-age=3600, public", response.headers["Cache-Control"]
  end

  test "should generate ETag for conditional requests" do
    # Skip this test in development environment where ETags are disabled
    skip "ETags disabled in development" if Rails.env.development?

    get :show, format: :xml

    assert_response :success
    assert_not_nil response.headers["ETag"]
  end

  test "should return 304 for conditional requests with matching ETag" do
    # Skip this test in development environment
    skip "ETags disabled in development" if Rails.env.development?

    # First request to get the ETag
    get :show, format: :xml
    assert_response :success
    etag = response.headers["ETag"]

    # Second request with If-None-Match header
    @request.env["HTTP_IF_NONE_MATCH"] = etag
    get :show, format: :xml

    assert_response :not_modified
  end

  test "should cache sitemap content" do
    # Skip this test in development environment where caching is disabled
    skip "Caching disabled in development" if Rails.env.development?

    # Clear cache first
    Rails.cache.clear

    # Track cache operations using ActiveSupport::Notifications
    cache_writes = []
    cache_reads = []

    write_subscription = ActiveSupport::Notifications.subscribe("cache_write.active_support") do |*args|
      cache_writes << args.last[:key] if args.last[:key].include?("sitemap")
    end

    read_subscription = ActiveSupport::Notifications.subscribe("cache_read.active_support") do |*args|
      cache_reads << args.last[:key] if args.last[:key].include?("sitemap")
    end

    begin
      # First request should generate and cache content
      get :show, format: :xml
      assert_response :success

      # Should have written to cache
      assert cache_writes.any?, "Expected cache write operation for sitemap"
      initial_writes = cache_writes.size

      # Clear read tracking for second request
      cache_reads.clear

      # Second request should read from cache
      get :show, format: :xml
      assert_response :success

      # Should have read from cache without additional writes
      assert cache_reads.any?, "Expected cache read operation for sitemap"
      assert_equal initial_writes, cache_writes.size, "Expected no additional cache writes on second request"
    ensure
      ActiveSupport::Notifications.unsubscribe(write_subscription)
      ActiveSupport::Notifications.unsubscribe(read_subscription)
    end
  end

  test "should invalidate cache when experience count changes" do
    # First request to establish baseline
    get :show, format: :xml
    assert_response :success

    initial_xml = response.body
    xml_doc = Nokogiri::XML(initial_xml)
    initial_urls = xml_doc.xpath("//xmlns:url/xmlns:loc", "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9").map(&:text)

    # Create a new approved experience (moderation already stubbed in setup)
    new_experience = Experience.create!(
      title: "Fresh New Experience",
      description: "This should change the cache and appear in sitemap",
      author: "Diana Prince",
      account: accounts(:one),
      approved: true
    )

    # Second request should include the new experience
    get :show, format: :xml
    assert_response :success

    updated_xml = response.body
    xml_doc = Nokogiri::XML(updated_xml)
    updated_urls = xml_doc.xpath("//xmlns:url/xmlns:loc", "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9").map(&:text)

    # The new experience should appear in the updated sitemap
    assert_includes updated_urls, "#{request.base_url}/experiences/#{new_experience.id}/display"
    # Should have more URLs than before
    assert updated_urls.size > initial_urls.size

    new_experience.destroy
  end

  test "should handle empty experience set gracefully" do
    # Remove all experiences
    Experience.delete_all

    get :show, format: :xml

    assert_response :success

    xml_doc = Nokogiri::XML(response.body)
    assert xml_doc.errors.empty?

    # Should still include main pages
    urls = xml_doc.xpath("//xmlns:url/xmlns:loc", "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9").map(&:text)
    assert_includes urls, request.base_url.to_s
    assert_includes urls, "#{request.base_url}/experiences"
  end

  test "should handle large number of experiences" do
    # Create many experiences to test performance (moderation already stubbed in setup)
    50.times do |i|
      Experience.create!(
        title: "Experience Number #{i}",
        description: "This is a test experience with number #{i}",
        author: "Test Author #{i}",
        account: accounts(:one),
        approved: true
      )
    end

    start_time = Time.current
    get :show, format: :xml
    end_time = Time.current

    assert_response :success

    # Should complete within reasonable time (5 seconds)
    assert (end_time - start_time) < 5.seconds, "Sitemap generation took too long"

    xml_doc = Nokogiri::XML(response.body)
    urls = xml_doc.xpath("//xmlns:url/xmlns:loc", "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9").map(&:text)

    # Should include all approved experiences
    experience_urls = urls.select { |url| url.include?("/experiences/") && url.include?("/display") }
    assert_operator experience_urls.size, :>=, 50

    # Clean up
    Experience.where("title LIKE 'Experience Number%'").delete_all
  end

  test "should have valid XML namespaces and structure" do
    get :show, format: :xml

    assert_response :success

    xml_doc = Nokogiri::XML(response.body)

    # Validate against sitemap schema expectations
    urlset = xml_doc.at_xpath("//xmlns:urlset", "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9")
    assert_equal "http://www.sitemaps.org/schemas/sitemap/0.9", urlset.namespace.href

    # Each URL should have required elements
    xml_doc.xpath("//xmlns:url", "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9").each do |url|
      assert_not_nil url.at_xpath("xmlns:loc", "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9"), "URL should have loc element"

      # Check optional elements are properly formatted if present
      lastmod = url.at_xpath("xmlns:lastmod", "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9")
      assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, lastmod.text) if lastmod

      changefreq = url.at_xpath("xmlns:changefreq", "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9")
      if changefreq
        valid_frequencies = %w[always hourly daily weekly monthly yearly never]
        assert_includes valid_frequencies, changefreq.text
      end

      priority = url.at_xpath("xmlns:priority", "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9")
      if priority
        priority_value = priority.text.to_f
        assert priority_value >= 0.0 && priority_value <= 1.0
      end
    end
  end

  test "should skip privacy consent and CSRF protection" do
    # These are controller-level configurations that should be tested
    skip_actions = @controller.class._process_action_callbacks
                              .select { |callback| callback.kind == :before }
                              .map(&:filter)

    assert_not_includes skip_actions, :_enforce_privacy_consent
    assert @controller.class.skip_forgery_protection
  end
end
