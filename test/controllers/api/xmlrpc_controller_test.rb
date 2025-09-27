require "test_helper"
require "nokogiri"

module Api
  class XmlrpcControllerTest < ActionController::TestCase
  # Don't use fixtures for this test
  self.use_transactional_tests = true

      setup do
      # Start with a clean slate
      ExperienceVector.delete_all
      Experience.delete_all
      UserPreference.delete_all

      # Skip certain before_action methods that could cause issues
      @controller.stubs(:apply_rate_limit).returns(true)
      # Skip CSRF verification for most tests (but we'll test it separately)
      @controller.stubs(:verify_csrf_for_state_changing_methods).returns(true)

    # Create two test experiences
    @experience1 = Experience.new(
      title: "Safe Experience One",
      description: "A safe description for the first experience",
      author: "Safe Author One",
      account: accounts(:one),
      approved: true
    )

    # Attach a basic HTML file for first experience
    html_content1 = "<html><body><h1>Safe Experience One</h1></body></html>"
    @experience1.html_file.attach(
      io: StringIO.new(html_content1),
      filename: "safe_experience_1.html",
      content_type: "text/html"
    )

    @experience1.save!

    @experience2 = Experience.new(
      title: "Safe Experience Two",
      description: "A safe description for the second experience",
      author: "Safe Author Two",
      account: accounts(:two),
      approved: true
    )

    # Attach a basic HTML file for second experience
    html_content2 = "<html><body><h1>Safe Experience Two</h1></body></html>"
    @experience2.html_file.attach(
      io: StringIO.new(html_content2),
      filename: "safe_experience_2.html",
      content_type: "text/html"
    )

    @experience2.save!

    # Create an unapproved experience for testing
    @unapproved_experience = Experience.new(
      title: "Unapproved Experience",
      description: "This experience needs approval",
      author: "Test Author",
      account: accounts(:one),
      approved: false
    )

    html_content3 = "<html><body><h1>Unapproved Experience</h1></body></html>"
    @unapproved_experience.html_file.attach(
      io: StringIO.new(html_content3),
      filename: "unapproved_experience.html",
      content_type: "text/html"
    )

    @unapproved_experience.save!

    # Set the XML content type for all requests
    @request.env["CONTENT_TYPE"] = "text/xml"
      end

  teardown do
    ExperienceVector.delete_all
    Experience.delete_all
    UserPreference.delete_all
  end

  test "should get all experiences" do
    xml_content = <<~XML
      <?xml version="1.0"?>
      <methodCall>
        <methodName>experiences.all</methodName>
        <params></params>
      </methodCall>
    XML

    post :endpoint, params: { xml: xml_content }

    assert_response :success

    xml_response = Nokogiri::XML(response.body)
    experiences = xml_response.xpath("//array/data/value")

    assert_equal 2, experiences.count
  end

  test "should get single experience" do
    xml_content = <<~XML
      <?xml version="1.0"?>
      <methodCall>
        <methodName>experiences.get</methodName>
        <params>
          <param><value><int>#{@experience1.id}</int></value></param>
        </params>
      </methodCall>
    XML

    post :endpoint, params: { xml: xml_content }

    assert_response :success

    xml_response = Nokogiri::XML(response.body)
    title = xml_response.xpath("//struct/member[name='title']/value/string").text
    assert_equal "Safe Experience One", title
  end

  test "should get approved experiences only" do
    xml_content = <<~XML
      <?xml version="1.0"?>
      <methodCall>
        <methodName>experiences.approved</methodName>
        <params></params>
      </methodCall>
    XML

    post :endpoint, params: { xml: xml_content }

    assert_response :success

    xml_response = Nokogiri::XML(response.body)
    experiences = xml_response.xpath("//array/data/value")

    # Should only return approved experiences
    assert_equal 2, experiences.count
  end

  test "should search experiences with public query" do
    xml_content = <<~XML
      <?xml version="1.0"?>
      <methodCall>
        <methodName>search.public_query</methodName>
        <params>
          <param><value><string>Safe</string></value></param>
          <param><value><int>10</int></value></param>
        </params>
      </methodCall>
    XML

    post :endpoint, params: { xml: xml_content }

    assert_response :success

    xml_response = Nokogiri::XML(response.body)
    experiences = xml_response.xpath("//array/data/value")

    assert_equal 2, experiences.count
  end

  test "should create experience when authenticated" do
    # Simulate authentication
    @controller.stubs(:current_account).returns(accounts(:one))

    xml_content = <<~XML
      <?xml version="1.0"?>
      <methodCall>
        <methodName>experiences.create</methodName>
        <params>
          <param><value><string>New Test Experience</string></value></param>
          <param><value><string>Test description</string></value></param>
          <param><value><string>&lt;html&gt;&lt;body&gt;&lt;h1&gt;Test&lt;/h1&gt;&lt;/body&gt;&lt;/html&gt;</string></value></param>
          <param><value><string>Test Author</string></value></param>
        </params>
      </methodCall>
    XML

    post :endpoint, params: { xml: xml_content }

    assert_response :success

    xml_response = Nokogiri::XML(response.body)
    title = xml_response.xpath("//struct/member[name='title']/value/string").text
    assert_equal "New Test Experience", title
  end

  test "should handle preferences.set" do
    # Simulate authentication
    @controller.stubs(:current_account).returns(accounts(:one))

    xml_content = <<~XML
      <?xml version="1.0"?>
      <methodCall>
        <methodName>preferences.set</methodName>
        <params>
          <param><value><string>dashboard-tutorial</string></value></param>
          <param><value><string>true</string></value></param>
        </params>
      </methodCall>
    XML

    post :endpoint, params: { xml: xml_content }

    assert_response :success

    xml_response = Nokogiri::XML(response.body)
    success = xml_response.xpath("//struct/member[name='success']/value/boolean").text
    assert_equal "1", success
  end

  test "should handle preferences.get" do
    # Simulate authentication and set a preference first
    @controller.stubs(:current_account).returns(accounts(:one))
    UserPreference.set(accounts(:one).id, "dashboard-tutorial", "t")

    xml_content = <<~XML
      <?xml version="1.0"?>
      <methodCall>
        <methodName>preferences.get</methodName>
        <params>
          <param><value><string>dashboard-tutorial</string></value></param>
        </params>
      </methodCall>
    XML

    post :endpoint, params: { xml: xml_content }

    assert_response :success

    xml_response = Nokogiri::XML(response.body)
    value = xml_response.xpath("//struct/member[name='value']/value/string").text
    assert_equal "t", value
  end

  test "should handle preferences.is_dismissed" do
    # Simulate authentication and set a dismissed preference
    @controller.stubs(:current_account).returns(accounts(:one))
    UserPreference.dismiss(accounts(:one).id, "welcome-message")

    xml_content = <<~XML
      <?xml version="1.0"?>
      <methodCall>
        <methodName>preferences.is_dismissed</methodName>
        <params>
          <param><value><string>welcome-message</string></value></param>
        </params>
      </methodCall>
    XML

    post :endpoint, params: { xml: xml_content }

    assert_response :success

    xml_response = Nokogiri::XML(response.body)
    dismissed = xml_response.xpath("//struct/member[name='dismissed']/value/boolean").text
    assert_equal "1", dismissed
  end

  test "should get account info when authenticated" do
    # Simulate authentication
    @controller.stubs(:current_account).returns(accounts(:one))

    xml_content = <<~XML
      <?xml version="1.0"?>
      <methodCall>
        <methodName>account.get_info</methodName>
        <params></params>
      </methodCall>
    XML

    post :endpoint, params: { xml: xml_content }

    assert_response :success

    xml_response = Nokogiri::XML(response.body)
    username = xml_response.xpath("//struct/member[name='username']/value/string").text
    assert_equal accounts(:one).username, username
  end

  test "should require authentication for protected methods" do
    # Don't authenticate
    @controller.stubs(:current_account).returns(nil)

    xml_content = <<~XML
      <?xml version="1.0"?>
      <methodCall>
        <methodName>experiences.create</methodName>
        <params>
          <param><value><string>Test</string></value></param>
        </params>
      </methodCall>
    XML

    post :endpoint, params: { xml: xml_content }

    assert_response :success

    xml_response = Nokogiri::XML(response.body)
    fault = xml_response.xpath("//fault/value/struct/member[name='faultCode']/value/int")

    assert fault.present?
    assert_equal "403", fault.text
  end

  test "should reject invalid preference keys" do
    # Simulate authentication
    @controller.stubs(:current_account).returns(accounts(:one))

    xml_content = <<~XML
      <?xml version="1.0"?>
      <methodCall>
        <methodName>preferences.get</methodName>
        <params>
          <param><value><string>invalid-key</string></value></param>
        </params>
      </methodCall>
    XML

    post :endpoint, params: { xml: xml_content }

    assert_response :success

    xml_response = Nokogiri::XML(response.body)
    fault = xml_response.xpath("//fault/value/struct/member[name='faultCode']/value/int")

    assert fault.present?
    assert_equal "500", fault.text
  end

  test "should reject deeply nested XML" do
    # Create a deeply nested XML document (more than 100 levels)
    xml_body = "<?xml version=\"1.0\"?>\n<methodCall><methodName>experiences.all</methodName><params>"
    150.times do |i|
      xml_body += "<struct><member><n>level#{i}</n><value>"
    end
    150.times do |_i|
      xml_body += "</value></member></struct>"
    end
    xml_body += "</params></methodCall>"

    post :endpoint, params: { xml: xml_body }

    assert_response :success

    xml_response = Nokogiri::XML(response.body)
    fault = xml_response.xpath("//fault/value/struct/member[name='faultCode']/value/int")

    assert fault.present?
    assert_equal "400", fault.text

    fault_string = xml_response.xpath("//fault/value/struct/member[name='faultString']/value/string")
    assert_match(/Invalid XML-RPC request/, fault_string.text)
  end

  test "should reject empty request body" do
    post :endpoint, params: { xml: "" }

    assert_response :success

    xml_response = Nokogiri::XML(response.body)
    fault = xml_response.xpath("//fault/value/struct/member[name='faultCode']/value/int")

    assert fault.present?
    assert_equal "400", fault.text

    fault_string = xml_response.xpath("//fault/value/struct/member[name='faultString']/value/string")
    assert_equal "Empty request body", fault_string.text
  end

  test "should reject invalid XML" do
    post :endpoint, params: { xml: "This is not XML" }

    assert_response :success

    xml_response = Nokogiri::XML(response.body)
    fault = xml_response.xpath("//fault/value/struct/member[name='faultCode']/value/int")

    assert fault.present?
    assert_equal "400", fault.text

    fault_string = xml_response.xpath("//fault/value/struct/member[name='faultString']/value/string")
    assert_equal "Invalid XML-RPC request", fault_string.text
  end

  test "should reject XML-RPC without method name" do
    xml_content = <<~XML
      <?xml version="1.0"?>
      <methodCall>
        <params>
        </params>
      </methodCall>
    XML

    post :endpoint, params: { xml: xml_content }

    assert_response :success

    xml_response = Nokogiri::XML(response.body)
    fault = xml_response.xpath("//fault/value/struct/member[name='faultCode']/value/int")

    assert fault.present?
    assert_equal "400", fault.text

    fault_string = xml_response.xpath("//fault/value/struct/member[name='faultString']/value/string")
    assert_match(/No methodName element found/, fault_string.text)
  end

  test "should require CSRF token for state-changing XML-RPC methods" do
    # Remove the CSRF stub to test actual CSRF protection
    @controller.unstub(:verify_csrf_for_state_changing_methods)
    @controller.stubs(:current_account).returns(accounts(:one))

    xml_content = <<~XML
      <?xml version="1.0"?>
      <methodCall>
        <methodName>experiences.create</methodName>
        <params>
          <param><value><string>Test Experience</string></value></param>
          <param><value><string>Test description</string></value></param>
        </params>
      </methodCall>
    XML

    # Attempt to create experience without CSRF token
    post :endpoint, params: { xml: xml_content }

    assert_response :success

    xml_response = Nokogiri::XML(response.body)
    fault = xml_response.xpath("//fault/value/struct/member[name='faultCode']/value/int")

    assert fault.present?
    assert_equal "403", fault.text

    fault_string = xml_response.xpath("//fault/value/struct/member[name='faultString']/value/string")
    assert_equal "CSRF token missing or invalid", fault_string.text
  end

  test "should allow state-changing XML-RPC methods with valid CSRF token" do
    # Remove the CSRF stub to test actual CSRF protection
    @controller.unstub(:verify_csrf_for_state_changing_methods)
    @controller.stubs(:current_account).returns(accounts(:one))

    # Temporarily disable moderation for this test
    Experience.any_instance.stubs(:content_moderation).returns(nil)

    # Get a valid CSRF token
    csrf_token = @controller.send(:form_authenticity_token)

    xml_content = <<~XML
      <?xml version="1.0"?>
      <methodCall>
        <methodName>experiences.create</methodName>
        <params>
          <param><value><string>Test Experience</string></value></param>
          <param><value><string>Test description</string></value></param>
        </params>
      </methodCall>
    XML

    # Set the CSRF token header
    @request.env["HTTP_X_CSRF_TOKEN"] = csrf_token

    # Attempt to create experience with CSRF token
    post :endpoint, params: { xml: xml_content }

    assert_response :success

    xml_response = Nokogiri::XML(response.body)
    # Should not have a fault
    fault = xml_response.xpath("//fault")
    assert fault.empty?

    # Should have a successful response
    response_element = xml_response.xpath("//methodResponse")
    assert response_element.present?
  end

  test "should allow read-only XML-RPC methods without CSRF token" do
    # Remove the CSRF stub to test that read-only methods work without CSRF
    @controller.unstub(:verify_csrf_for_state_changing_methods)

    xml_content = <<~XML
      <?xml version="1.0"?>
      <methodCall>
        <methodName>experiences.all</methodName>
        <params></params>
      </methodCall>
    XML

    post :endpoint, params: { xml: xml_content }

    assert_response :success

    xml_response = Nokogiri::XML(response.body)
    # Should not have a fault
    fault = xml_response.xpath("//fault")
    assert fault.empty?

    # Should have a successful response
    response_element = xml_response.xpath("//methodResponse")
    assert response_element.present?
  end
  end
end
